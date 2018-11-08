-- BPE Experiments Two
-- Glenn Berry, SQLskills.com

-- Turn on IO and Time statistics
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- Statistics IO does not differentiate between logical reads and BPE reads


-- Flush the buffer cache (This will also flush the BPE)
DBCC DROPCLEANBUFFERS;

-- Set Max server memory to 8192
EXEC sys.sp_configure N'show advanced options', N'1'  RECONFIGURE WITH OVERRIDE;
GO
EXEC sys.sp_configure N'max server memory (MB)', N'8192';
GO
RECONFIGURE WITH OVERRIDE;
GO

-- Switch to correct database
--USE NoCompressionTest;
USE [portal];
GO

SET NOCOUNT ON;

-- Query non-compressed table, causing a clustered index scan 
-- (34335ms elapsed time with a cold buffer pool and Max Server Memory set to 8192)
--SELECT OnlineSearchHistoryID, SearchTerm, NumItemsRequested, NumItemsReturned, 
--       SearchElapsedTime, SearchDateTime, SearchSPName
--FROM dbo.OnlineSearchHistoryNonCompressed  -- Table has 151 million rows
--WHERE SearchSPName = N'GetOnlineSearchResultsContains';
SELECT OnlineSearchHistoryID, SearchTerm, NumItemsRequested, NumItemsReturned, 
       SearchElapsedTime, SearchDateTime, SearchSPName
FROM [dbo].[EventsData] AS [ed]  -- Table has 151 million rows
WHERE SearchSPName = N'GetOnlineSearchResultsContains';

-- Force a clustered index scan with a query hint
-- (33105 ms)
SELECT COUNT(*) AS [Row Count]
--FROM dbo.OnlineSearchHistoryNonCompressed WITH (INDEX(0)); 
--FROM [dbo].[EventsData] AS [ed] WITH (INDEX(0)); 
FROM [dbo].[VitalsData] AS [vd] WITH (INDEX(0)); 


-- Breaks down buffers used by current database by object (table, index) in the buffer cache  
SELECT OBJECT_NAME(p.[object_id]) AS [Object Name], p.index_id, 
CAST(COUNT(*)/128.0 AS DECIMAL(10, 2)) AS [Buffer size(MB)],  
COUNT(*) AS [BufferCount], p.Rows AS [Row Count],
p.data_compression_desc AS [Compression Type]
FROM sys.allocation_units AS a WITH (NOLOCK)
INNER JOIN sys.dm_os_buffer_descriptors AS b WITH (NOLOCK)
ON a.allocation_unit_id = b.allocation_unit_id
INNER JOIN sys.partitions AS p WITH (NOLOCK)
ON a.container_id = p.hobt_id
WHERE b.database_id = CONVERT(int,DB_ID())
AND p.[object_id] > 100
--AND b.is_in_bpool_extension = 1
GROUP BY p.[object_id], p.index_id, p.data_compression_desc, p.[Rows]
ORDER BY [BufferCount] DESC OPTION (RECOMPILE);


-- Look at buffer descriptors to see BPE usage
SELECT DB_NAME(database_id) AS [Database Name], COUNT(page_id) AS [Page Count],
       CAST(COUNT(*)/128.0 AS DECIMAL(10, 2)) AS [Buffer size(MB)]
FROM sys.dm_os_buffer_descriptors
WHERE database_id <> 32767
AND is_in_bpool_extension = 1
GROUP BY DB_NAME(database_id);


-- Query non-compressed table, causing a clustered index scan 
-- (31598ms elapsed time with a warm buffer pool and MaxServerMemory set to 8192)
SELECT OnlineSearchHistoryID, SearchTerm, NumItemsRequested, NumItemsReturned, 
       SearchElapsedTime, SearchDateTime, SearchSPName
FROM dbo.OnlineSearchHistoryNonCompressed  -- Table has 151 million rows
WHERE SearchTerm = N'Jessica';