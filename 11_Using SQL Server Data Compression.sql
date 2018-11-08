-- SQLskills.com
-- Glenn Berry
-- SQL Server Data Compression Examples

USE [NoCompressionTest];
GO


-- Get Table names, row counts, and compression status for the clustered index or heap for every table  
SELECT OBJECT_NAME(object_id) AS [ObjectName], 
SUM(Rows) AS [RowCount], data_compression_desc AS [CompressionType]
FROM sys.partitions WITH (NOLOCK)
WHERE index_id < 2 --ignore the partitions from the non-clustered index if any
AND OBJECT_NAME(object_id) NOT LIKE N'sys%'
AND OBJECT_NAME(object_id) NOT LIKE N'queue_%' 
AND OBJECT_NAME(object_id) NOT LIKE N'filestream_tombstone%' 
AND OBJECT_NAME(object_id) NOT LIKE N'fulltext%'
AND OBJECT_NAME(object_id) NOT LIKE N'ifts_comp_fragment%'
AND OBJECT_NAME(object_id) NOT LIKE N'filetable_updates%'
AND OBJECT_NAME(object_id) NOT LIKE N'xml_index_nodes%'
AND OBJECT_NAME(object_id) NOT LIKE N'sqlagent_job%'
AND OBJECT_NAME(object_id) NOT LIKE N'plan_persist_%'
GROUP BY object_id, data_compression_desc
ORDER BY SUM(Rows) DESC;

-- Gives you an idea of table sizes, and possible data compression opportunities



--- Index Read/Write stats (all tables in current DB) ordered by Reads  
SELECT OBJECT_NAME(s.[object_id]) AS [ObjectName], i.name AS [IndexName], i.index_id,
	   user_seeks + user_scans + user_lookups AS [Reads], s.user_updates AS [Writes],  
	   i.type_desc AS [IndexType], i.fill_factor AS [FillFactor], i.has_filter, i.filter_definition, 
	   s.last_user_scan, s.last_user_lookup, s.last_user_seek
FROM sys.dm_db_index_usage_stats AS s WITH (NOLOCK)
INNER JOIN sys.indexes AS i WITH (NOLOCK)
ON s.[object_id] = i.[object_id]
WHERE OBJECTPROPERTY(s.[object_id],'IsUserTable') = 1
AND i.index_id = s.index_id
AND s.database_id = DB_ID()
ORDER BY user_seeks + user_scans + user_lookups DESC OPTION (RECOMPILE); 

-- Show which indexes in the current database are most active for Reads


--- Index Read/Write stats (all tables in current DB) ordered by Writes  
SELECT OBJECT_NAME(s.[object_id]) AS [ObjectName], i.name AS [IndexName], i.index_id,
	   s.user_updates AS [Writes], user_seeks + user_scans + user_lookups AS [Reads], 
	   i.type_desc AS [IndexType], i.fill_factor AS [FillFactor], i.has_filter, i.filter_definition,
	   s.last_system_update, s.last_user_update
FROM sys.dm_db_index_usage_stats AS s WITH (NOLOCK)
INNER JOIN sys.indexes AS i WITH (NOLOCK)
ON s.[object_id] = i.[object_id]
WHERE OBJECTPROPERTY(s.[object_id],'IsUserTable') = 1
AND i.index_id = s.index_id
AND s.database_id = DB_ID()
ORDER BY s.user_updates DESC OPTION (RECOMPILE);						 

-- Show which indexes in the current database are most active for Writes

-- sp_estimate_data_compression_savings
-- https://msdn.microsoft.com/en-us/library/cc280574.aspx

-- Check how much space you might save with PAGE data compression
EXEC sp_estimate_data_compression_savings N'dbo', 
N'OnlineSearchHistoryNonCompressed', NULL, NULL, N'PAGE';

	-- Clustered index results
	SELECT 18654560/1024 AS [Size (MB) with current compression]; -- 18217 MB
	SELECT 4583600/1024 AS [Size (MB) with PAGE compression];     --  4476 MB

	-- Index ID 3 results
	SELECT 8131648/1024 AS [Size (MB) with current compression];  --  7941 MB
	SELECT 2324352/1024 AS [Size (MB) with PAGE compression];     --  2269 MB


-- Check how much space you might save with ROW data compression
EXEC sp_estimate_data_compression_savings N'dbo', 
N'OnlineSearchHistoryNonCompressed', NULL, NULL, N'ROW';

	-- Clustered index results
	SELECT 18654560/1024 AS [Size (MB) with current compression]; -- 18217 MB
	SELECT 10652816/1024 AS [Size (MB) with ROW compression];     -- 10403 MB

	-- Index ID 3 results
	SELECT 8131648/1024 AS [Size (MB) with current compression];  --  7941 MB
	SELECT 5074992/1024 AS [Size (MB) with ROW compression];      --  4956 MB




-- Finally, compress the indexes


-- Compress the clustered index or heap with PAGE compression
ALTER INDEX [PK_OnlineSearchHistoryNonCompressed] ON [dbo].[OnlineSearchHistoryNonCompressed] 
REBUILD PARTITION = ALL WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, 
SORT_IN_TEMPDB = OFF, ONLINE = ON, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, 
DATA_COMPRESSION = PAGE, MAXDOP = 1);


-- Compress the non-clustered index with PAGE compression
ALTER INDEX [IX_OnlineSearchHistoryNonCompressed_SearchTerm] ON [dbo].[OnlineSearchHistoryNonCompressed] 
REBUILD PARTITION = ALL WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, 
SORT_IN_TEMPDB = OFF, ONLINE = ON, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, 
DATA_COMPRESSION = PAGE, MAXDOP = 1);


