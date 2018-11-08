-- Resource Governor Testing
-- Glenn Berry
-- SQLskills

-- Make sure you are using LimitedIO SQL Server login

-- Confirm your login information (should be LimitedIO SQL Server login)
SELECT SUSER_NAME() As [Current Login];


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


-- Generate a big sequential read with an index hint
-- to force a clustered index scan or a table scan
SELECT COUNT(*) AS [Row Count]
FROM dbo.TestData WITH (INDEX(0)); 

-- Takes about 14 seconds


-- Get I/O metrics from resource pools
SELECT pool_id, name, min_iops_per_volume, max_iops_per_volume, read_io_queued_total,
read_io_issued_total, read_io_completed_total,read_io_throttled_total, read_bytes_total,
read_io_stall_total_ms, read_io_stall_queued_ms, io_issue_violations_total,io_issue_delay_total_ms
FROM sys.dm_resource_governor_resource_pools WITH (NOLOCK)
WHERE name <> N'internal'; 

-- Get I/O metrics from resource pool volumes
SELECT pool_id, volume_name, read_io_queued_total,
read_io_issued_total, read_io_completed_total,read_io_throttled_total, read_bytes_total,
read_io_stall_total_ms, read_io_stall_queued_ms, io_issue_violations_total,io_issue_delay_total_ms 
FROM sys.dm_resource_governor_resource_pool_volumes WITH (NOLOCK);

-- Find out what sessions are in each group
SELECT s.group_id, g.name AS [Workload Group Name],
s.status, s.session_id, s.login_time, 
s.host_name AS [Host Name], 
s.program_name AS [Program Name]
FROM sys.dm_exec_sessions AS s
INNER JOIN sys.dm_resource_governor_workload_groups AS g
ON g.group_id = s.group_id
WHERE s.session_id > 50
ORDER BY g.name


-- Change Resource Pool properties to raise IO limit to 500
ALTER RESOURCE POOL LimitedIOPool
WITH (MIN_IOPS_PER_VOLUME = 1, MAX_IOPS_PER_VOLUME = 500);
GO
ALTER RESOURCE GOVERNOR RECONFIGURE;
GO

-- Run read test again

-- Flush dirty pages to disk
CHECKPOINT;

-- Flush buffer pool (don't do this in Production)
-- This will force SQL Server to do physical reads
DBCC DROPCLEANBUFFERS;


-- Generate a big sequential read with an index hint
-- to force a clustered index scan or a table scan
SELECT COUNT(*) AS [Row Count]
FROM dbo.TestData WITH (INDEX(0)); 

-- Takes about 8 seconds