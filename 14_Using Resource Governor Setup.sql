-- Resource Governor Setup
-- Glenn Berry
-- SQLskills


USE [master]; 
GO

-- Create resource pool with your desired resource limits
CREATE RESOURCE POOL LimitedIOPool WITH
(MIN_IOPS_PER_VOLUME = 1, MAX_IOPS_PER_VOLUME = 300);
GO

-- Create workload group that uses the resource pool
CREATE WORKLOAD GROUP LimitedIOGroup
USING LimitedIOPool;
GO

-- Create classifier function in master database to route connections to your workload group and pool
CREATE FUNCTION dbo.LimitedIO()
RETURNS SYSNAME WITH SCHEMABINDING
AS
	BEGIN
		DECLARE @GroupName SYSNAME;
       
		IF SUSER_NAME() = N'LimitedIO'
			BEGIN
				SET @GroupName = N'LimitedIOGroup';
			END
		ELSE
			BEGIN
				SET @GroupName = N'default';
			END
		RETURN @GroupName;
	END
GO

-- Assign the classifier function to the resource governor
ALTER RESOURCE GOVERNOR WITH (CLASSIFIER_FUNCTION = dbo.LimitedIO);
GO

-- Reconfigure Resource Governor to enable the new workload group and resource pool
ALTER RESOURCE GOVERNOR RECONFIGURE;
GO


USE [master]; 
GO

-- Get in-memory resource governor configuration information
SELECT OBJECT_SCHEMA_NAME(classifier_function_id) AS [schema_name],
       OBJECT_NAME(classifier_function_id) AS [function_name], 
	   is_reconfiguration_pending, [max_outstanding_io_per_volume]
FROM sys.dm_resource_governor_configuration;

-- Get stored resource governor configuration information
SELECT OBJECT_SCHEMA_NAME(classifier_function_id) AS [schema_name], 
       OBJECT_NAME(classifier_function_id) AS [function_name],
	   is_enabled, [max_outstanding_io_per_volume] 
FROM sys.resource_governor_configuration;




-- Create LimitedIO SQL Server login
CREATE LOGIN LimitedIO WITH PASSWORD = N'LimitedIO', 
DEFAULT_DATABASE = ResourceGovernorTest, CHECK_EXPIRATION = OFF, CHECK_POLICY = OFF;
GO
ALTER SERVER ROLE [sysadmin] ADD MEMBER [LimitedIO];
GO

-- Create LimitedIO user in database and associate with LimitedIO SQL Server login
USE ResourceGovernorTest;
GO
CREATE USER LimitedIO FOR LOGIN LimitedIO;
GO
ALTER ROLE db_owner ADD MEMBER LimitedIO;
GO

-- Take a look at Resource Governor properties in Object Explorer

-- Switch to the correct database
USE ResourceGovernorTest;
GO

-- Don't return row counts
SET NOCOUNT ON;

-- Flush dirty pages to disk
CHECKPOINT;

-- Flush buffer pool (don't do this in Production)
-- This will force SQL Server to do physical reads
DBCC DROPCLEANBUFFERS;


EXEC sp_spaceused N'dbo.TestData';

-- Generate a big sequential read with an index hint
-- to force a clustered index scan or a table scan
SELECT COUNT(*) AS [Row Count]
FROM dbo.TestData WITH (INDEX(0));
 
-- Takes about 2-3 seconds with no I/O throttling

-- Switch to other connection


-- Cleanup ****************************


-- Disable Resource Governor
ALTER RESOURCE GOVERNOR DISABLE;
GO

-- Drop workload group
DROP WORKLOAD GROUP LimitedIOGroup;
GO

-- Drop resource pool
DROP RESOURCE POOL LimitedIOPool;
GO
ALTER RESOURCE GOVERNOR RECONFIGURE;
GO

-- Unassign the classifier function
ALTER RESOURCE GOVERNOR WITH (CLASSIFIER_FUNCTION = NULL);
GO

-- Disable Resource Governor
ALTER RESOURCE GOVERNOR DISABLE;
GO

-- Remove classifier function from master database
USE [master]
GO
DROP FUNCTION dbo.LimitedIO;
GO

-- Remove user from database
USE [ResourceGovernorTest]
GO
DROP USER [LimitedIO]
GO

-- Remove SQL Server login
USE [master]
GO
DROP LOGIN [LimitedIO]
GO


-- Resource Governor
-- https://msdn.microsoft.com/en-us/library/bb933866(v=sql.120).aspx

-- Resource Governor Resource Pool
-- https://msdn.microsoft.com/en-us/library/hh510189(v=sql.120).aspx






