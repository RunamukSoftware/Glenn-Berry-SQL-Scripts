
-- Database scoped T-SQL Commands in SQL Server 2016 RC0 and later
-- Glenn Berry
-- SQLskills.com


-- Get database scoped configuration values for current database 
SELECT configuration_id, name, [value] AS [value_for_primary], value_for_secondary
FROM sys.database_scoped_configurations WITH (NOLOCK) OPTION (RECOMPILE);

  
-- ALTER DATABASE SCOPED CONFIGURATION (Transact-SQL)
-- https://msdn.microsoft.com/en-us/library/mt629158.aspx

 
-- The commands for the secondary database affect ALL secondary databases in an AlwaysOn AG
USE [CHECKDBTest]
GO

 
-- Enable legacy Cardinality Estimation for Primary database
-- Equivalent to using TF 4136, except this is only for this database
ALTER DATABASE SCOPED CONFIGURATION 
SET LEGACY_CARDINALITY_ESTIMATION = ON;
GO

 -- Enable legacy Cardinality Estimation for Secondary database
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY 
SET LEGACY_CARDINALITY_ESTIMATION = ON;
GO

-- Set legacy Cardinality Estimation for the Secondary database(s) to the same value as the Primary database
-- This is the default setting
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY 
SET LEGACY_CARDINALITY_ESTIMATION = PRIMARY;
GO

 
-- Disable parameter sniffing for Primary database
ALTER DATABASE SCOPED CONFIGURATION SET PARAMETER_SNIFFING = OFF;
GO

-- Disable parameter sniffing for Secondary database
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET PARAMETER_SNIFFING = OFF;
GO

 
-- Set parameter sniffing for the Secondary database(s) to the same value as the Primary database
-- This is the default setting
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY    
SET PARAMETER_SNIFFING = PRIMARY;
GO

 
-- Enable query optimizer fixes for Primary database
-- Equivalent to using TF 4199, except this is only for this database
ALTER DATABASE SCOPED CONFIGURATION 
SET QUERY_OPTIMIZER_HOTFIXES = ON;
GO

-- Enable query optimizer fixes for Secondary database
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY 
SET QUERY_OPTIMIZER_HOTFIXES = ON;
GO

 
-- Set MAXDOP for Primary database
ALTER DATABASE SCOPED CONFIGURATION 
SET MAXDOP = 4;
GO

 
-- Set MAXDOP for Secondary database(s)
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY 
SET MAXDOP = 4;
GO

-- Set MAXDOP for the Secondary database(s) to the same value as the Primary database
-- This is the default setting
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY 
SET MAXDOP = PRIMARY; 

 
-- Clear plan cache for current database (only possible for Primary database)
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO
