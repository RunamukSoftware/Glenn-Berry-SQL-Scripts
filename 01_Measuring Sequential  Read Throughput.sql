-- Measuring Sequential Read Throughput
-- aka "How to humble your SAN"
-- Glenn Berry, SQLskills.com

-- Flush any dirty pages
CHECKPOINT;

-- Flush the buffer cache
-- (Don't do this in Production)
DBCC DROPCLEANBUFFERS;
GO


-- Turn on I/O statistics and time statistics
SET STATISTICS IO ON; 
SET STATISTICS TIME ON;
GO

-- Use a database with a large table
--USE NoCompressionTest;
USE [portal];
GO

-- How big is the table?
-- About 17.8 GB, 151 million rows
--EXEC sp_spaceused N'OnlineSearchHistoryNonCompressed';
EXEC sp_spaceused N'VitalsData';

-- Generate a big sequential read with an index hint
-- to force a clustered index scan or a table scan
SELECT COUNT(*) AS [Row Count]
--FROM dbo.OnlineSearchHistoryNonCompressed WITH (INDEX(0)); 
FROM dbo.[VitalsData] AS [ed] WITH (INDEX(0)); 


 -- Formula for calculating sequential read throughput from IO and time statistics
 -- 8 (KB/page) * (physical reads + read-ahead reads)/(elapsed time in ms)

 -- Copy/paste numbers below from statistics io and statistics time output

 -- Check sequential throughput results (MB/sec)
 SELECT 8 * (2 + 2331787)/34327 AS [MB/sec Sequential Read Throughput];
-- = 543 MB/sec

-- Check elapsed time (table size in MB/read rate (MB/s) = Elapsed time in seconds
SELECT (18624424/1024.0)/543 AS [ Elapsed Time in Seconds];



-- Reading Pages from TechNet
http://technet.microsoft.com/en-us/library/ms191475(v=SQL.105).aspx


-- Disable read-ahead reads (don't do this in Production)
DBCC TRACEON (652);
DBCC TRACESTATUS;
DBCC TRACEOFF (652);


