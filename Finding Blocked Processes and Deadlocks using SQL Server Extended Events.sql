-- Finding Blocked Processes and Deadlocks using SQL Server Extended Events
-- by Jeremiah Peschka March 12, 2014 - 43 comments
-- https://www.brentozar.com/archive/2014/03/extended-events-doesnt-hard/

-- A lot of folks would have you think that Extended Events need to be complicated and involve copious amounts of XML shredding and throwing things across the office. I'm here to tell you that it doesn't have to be so bad.

--COLLECTING BLOCKED PROCESS REPORTS AND DEADLOCKS USING EXTENDED EVENTS

--When you want to find blocking, you probably turn to the blocked process report. You mess around with profiler on your SQL Server 2012 box. You probably feel a little bit dirty for clunking around in that old interface, but it gets the job done.

--There's a better way… Well, there is at least a less awful way: Extended Events.

CREATE EVENT SESSION [blocked_process] ON SERVER
ADD EVENT sqlserver.blocked_process_report(
    ACTION(sqlserver.client_app_name,
           sqlserver.client_hostname,
           sqlserver.database_name)) ,
ADD EVENT sqlserver.xml_deadlock_report (
    ACTION(sqlserver.client_app_name,
           sqlserver.client_hostname,
           sqlserver.database_name))
ADD TARGET package0.asynchronous_file_target
(SET filename = N'C:\SLBin\blocked_process.xel',
     --metadatafile = N'C:\SLBin\blocked_process.xem',
     max_file_size=(65536),
     max_rollover_files=5)
WITH (MAX_DISPATCH_LATENCY = 5SECONDS)
GO

/* Make sure this path exists before you start the trace! */

--WITH that, you've created an Extended Events session to grab blocked processes and deadlocks. Why both? The blocked process report makes use of the deadlock detector. Since large amounts of blocking are frequently synonymous with deadlocking, it makes sense to grab both at the same time. There are a few other things we'll need to do to make sure you can collect blocked processes:

EXEC sp_configure 'show advanced options', 1 ;
GO
RECONFIGURE ;
GO

/* Enabled the blocked process report */
EXEC sp_configure 'blocked process threshold', '5';
RECONFIGURE
GO

/* Start the Extended Events session */
ALTER EVENT SESSION [blocked_process] ON SERVER
STATE = START;

--At this point, you'll be collecting the blocked process report with Extended Events. There's no profiler session to set up, just start and stop the Extended Event session at your leisure.

--READING THE BLOCK PROCESS REPORT FROM EXTENDED EVENTS

--We're saving the blocked process report to disk using Extended Events. Now what?

--We need to get that blocked process data out of the Extended Events files and somewhere that we can better analyze it.

WITH events_cte AS (
  SELECT
    xevents.event_data,
    DATEADD(mi,
    DATEDIFF(mi, GETUTCDATE(), CURRENT_TIMESTAMP),
    xevents.event_data.value(
      '(event/@timestamp)[1]', 'datetime2')) AS [event time] ,
    xevents.event_data.value(
      '(event/action[@name="client_app_name"]/value)[1]', 'nvarchar(128)')
      AS [client app name],
    xevents.event_data.value(
      '(event/action[@name="client_hostname"]/value)[1]', 'nvarchar(max)')
      AS [client host name],
    xevents.event_data.value(
      '(event[@name="blocked_process_report"]/data[@name="database_name"]/value)[1]', 'nvarchar(max)')
      AS [database name],
    xevents.event_data.value(
      '(event[@name="blocked_process_report"]/data[@name="database_id"]/value)[1]', 'int')
      AS [database_id],
    xevents.event_data.value(
      '(event[@name="blocked_process_report"]/data[@name="object_id"]/value)[1]', 'int')
      AS [object_id],
    xevents.event_data.value(
      '(event[@name="blocked_process_report"]/data[@name="index_id"]/value)[1]', 'int')
      AS [index_id],
    xevents.event_data.value(
      '(event[@name="blocked_process_report"]/data[@name="duration"]/value)[1]', 'bigint') / 1000
      AS [duration (ms)],
    xevents.event_data.value(
      '(event[@name="blocked_process_report"]/data[@name="lock_mode"]/text)[1]', 'varchar')
      AS [lock_mode],
    xevents.event_data.value(
      '(event[@name="blocked_process_report"]/data[@name="login_sid"]/value)[1]', 'int')
      AS [login_sid],
    xevents.event_data.query(
      '(event[@name="blocked_process_report"]/data[@name="blocked_process"]/value/blocked-process-report)[1]')
      AS blocked_process_report,
    xevents.event_data.query(
      '(event/data[@name="xml_report"]/value/deadlock)[1]')
      AS deadlock_graph
  FROM    sys.fn_xe_file_target_read_file
    ('C:\SLBin\blocked_process*.xel',
     --'C:\SLBin\blocked_process*.xem',
     NULL,
     null, null)
    CROSS APPLY (SELECT CAST(event_data AS XML) AS event_data) as xevents
)
SELECT
  CASE WHEN blocked_process_report.value('(blocked-process-report[@monitorLoop])[1]', 'nvarchar(max)') IS NULL
       THEN 'Deadlock'
       ELSE 'Blocked Process'
       END AS ReportType,
  [event time],
  CASE [client app name] WHEN '' THEN ' -- N/A -- '
                         ELSE [client app name]
                         END AS [client app _name],
  CASE [client host name] WHEN '' THEN ' -- N/A -- '
                          ELSE [client host name]
                          END AS [client host name],
  [database name],
  COALESCE(OBJECT_SCHEMA_NAME(object_id, database_id), ' -- N/A -- ') AS [schema],
  COALESCE(OBJECT_NAME(object_id, database_id), ' -- N/A -- ') AS [table],
  index_id,
  [duration (ms)],
  lock_mode,
  COALESCE(SUSER_NAME(login_sid), ' -- N/A -- ') AS username,
  CASE WHEN blocked_process_report.value('(blocked-process-report[@monitorLoop])[1]', 'nvarchar(max)') IS NULL
       THEN deadlock_graph
       ELSE blocked_process_report
       END AS Report
FROM events_cte
ORDER BY [event time] DESC ;

--In this query, you read from an Extended Events session that's being saved to disk and perform XML shredding to get client information. It isn't a pretty query, but it does the job very well.

--VIEWING THE EXTENDED EVENTS DEADLOCK GRAPHS

--Extended Events deadlock graphs use a slightly different XML schema than what SSMS expects. You should see an error along the lines of “There is an error in XML document”. For folks using SQL Server 2012 and earlier, you can either parse the XML by hand or use SQL Sentry Plan Explorer.

--VIEWING THE EXTENDED EVENTS BLOCKED PROCESS REPORT

--But what about the blocked process report? After all, your users are complaining about blocking, right?

--Michael J. Swart has created tools to view the blocked process report. It'd be awesome if you could use it, but Michael's blocked process report viewer uses the output of a server side trace to read blocking information. These Extended Events files are different enough that you can't use them outright. You can, however, create a table that will let you use the blocked process report viewer:

CREATE TABLE bpr (
    EndTime DATETIME,
    TextData XML,
    EventClass INT DEFAULT(137)
);
GO
WITH events_cte AS (
    SELECT
        DATEADD(mi,
        DATEDIFF(mi, GETUTCDATE(), CURRENT_TIMESTAMP),
        xevents.event_data.value('(event/@timestamp)[1]',
           'datetime2')) AS [event_time] ,
        xevents.event_data.query('(event[@name="blocked_process_report"]/data[@name="blocked_process"]/value/blocked-process-report)[1]')
            AS blocked_process_report
    FROM    sys.fn_xe_file_target_read_file
        ('C:\SLBin\blocked_process*.xel',
         --'C:\SLBin\blocked_process*.xem',
         NULL,
         null, null)
        CROSS APPLY (SELECT CAST(event_data AS XML) AS event_data) as xevents
)
INSERT INTO bpr (EndTime, TextData)
SELECT
    [event_time],
    blocked_process_report
FROM events_cte
WHERE blocked_process_report.value('(blocked-process-report[@monitorLoop])[1]', 'nvarchar(max)') IS NOT NULL
ORDER BY [event_time] DESC ;
EXEC sp_blocked_process_report_viewer @Trace='bpr', @Type='TABLE';

--While you still have to read the XML yourself, this will give you a view into how deep the blocking hierarchies can go. Collecting this data with Extended Events mean that you won't have to sit at your desk, running queries, and waiting for blocking occur.

--EXTENDED EVENTS – NOT THAT HARD

--Extended Events aren't difficult to use. They provide a wealth of information about SQL Server and make it easier to collect information from complex or difficult to diagnose scenarios. You really can collect as much or as little information as you want from SQL Server. When you get started, the vast majority of your work will be spent either looking up Extended Events to use or formatting the output of the queries into something meaningful.
