
-- BPE Experiments
-- Glenn Berry, SQLskills.com

-- BPE is available in both Standard Edition and Enterprise Edition
-- It is a more interesting feature for Standard Edition

-- Buffer Pool Extension to SSDs in SQL Server 2014
-- http://blogs.technet.com/b/dataplatforminsider/archive/2013/07/25/buffer-pool-extension-to-ssds-in-sql-server-2014.aspx



-- Get configuration values for instance (but BPE is not in sys.configurations)
SELECT name, value, value_in_use, [description], is_dynamic, is_advanced
FROM sys.configurations 
ORDER BY name;

-- See if buffer pool extension is enabled
SELECT [path], state_description, current_size_in_kb, 
CAST(current_size_in_kb/1048576.0 AS DECIMAL(10,2)) AS [Size (GB)]
FROM sys.dm_os_buffer_pool_extension_configuration;


-- Enable BPE and create 32GB cache file
ALTER SERVER CONFIGURATION
SET BUFFER POOL EXTENSION ON (FILENAME = 'L:\SSDCache\BPEFile.BPE', SIZE = 32 GB);


-- See if buffer pool extension is enabled
SELECT [path], state_description, current_size_in_kb, 
CAST(current_size_in_kb/1048576.0 AS DECIMAL(10,2)) AS [Size (GB)]
FROM sys.dm_os_buffer_pool_extension_configuration;

-- Do something that would cause memory pressure, such as some clustered index scans
-- to see if we can get any BPE usage


-- Look at buffer descriptors to see BPE usage
SELECT DB_NAME(database_id) AS [Database Name], COUNT(page_id) AS [Page Count],
CAST(COUNT(*)/128.0 AS DECIMAL(10, 2)) AS [Buffer size(MB)], 
AVG(read_microsec) AS [Avg Read Time (microseconds)]
FROM sys.dm_os_buffer_descriptors WITH (NOLOCK)
WHERE database_id <> 32767
AND is_in_bpool_extension = 1
GROUP BY DB_NAME(database_id) 
ORDER BY [Buffer size(MB)];


-- Disable BPE and delete the cache file
ALTER SERVER CONFIGURATION
SET BUFFER POOL EXTENSION OFF;