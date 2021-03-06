-- Set instance-level options
-- Glenn Berry, SQLskills.com

-- Get configuration values for instance 
SELECT name, value, value_in_use, [description] 
FROM sys.configurations WITH (NOLOCK)
ORDER BY name OPTION (RECOMPILE);


-- Set Instance-level options to more appropriate values

-- Enable backup checksum default (always enable)
EXEC sys.sp_configure 'backup checksum default', 1;
GO
RECONFIGURE WITH OVERRIDE;
GO
-- New setting for SQL Server 2014
-- Previous versions can use TF 3023


-- Enable backup compression default
EXEC sys.sp_configure 'backup compression default', 1;
GO
RECONFIGURE WITH OVERRIDE;
GO
-- Enable in most cases. Exceptions:
-- If you are using TDE
-- If you are using a 3rd party backup compression product
-- If you are under sustained, high CPU pressure

-- Change cost threshold for parallelism to a higher value
EXEC sys.sp_configure 'cost threshold for parallelism', 25;
GO
RECONFIGURE WITH OVERRIDE;
GO
-- This depends on your workload

-- Set max server memory to 27000MB
EXEC sys.sp_configure 'max server memory (MB)', 27000;
GO
RECONFIGURE WITH OVERRIDE;
GO


-- Change max degree of parallelism to 4 (number of physical cores in a NUMA node)
EXEC sys.sp_configure 'max degree of parallelism', 4;
GO
RECONFIGURE WITH OVERRIDE;
GO


-- Enable optimize for ad hoc workloads
EXEC sys.sp_configure 'optimize for ad hoc workloads', 1;
RECONFIGURE WITH OVERRIDE;
GO
-- Always enable


-- Enable remote admin connections
EXEC sys.sp_configure 'remote admin connections', 1;
RECONFIGURE WITH OVERRIDE;
GO


-- Change default database locations (for default instance
USE [master]
GO

-- Change default location for data files
EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', 
N'DefaultData', REG_SZ, N'C:\SQLData';
GO
-- Change default location for log files
EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', 
     N'DefaultLog', REG_SZ, N'C:\SQLLogs';
GO
-- Change default location for backup files
EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', 
N'BackupDirectory', REG_SZ, N'C:\SQLBackups1';
GO







