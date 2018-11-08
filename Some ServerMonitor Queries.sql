-- Some ServerMonitor queries
-- SQLskills.com
-- Glenn Berry 3-24-2014

USE ServerMonitor;
GO

-- Get some recent metrics
EXEC dbo.DBAdminGetRecentSQLServerMetrics 60;

-- Get Averages for all metrics
SELECT AVG(AvgTaskCount) AS [Average Task Count],
       AVG(AvgRunnableTaskCount) AS [Average Runnable Task Count],
	   AVG(AvgPendingIOCount) AS [Avg Pending IO Count],
	   AVG(SQLServerCPUUtilization) AS [Avg CPU Utilization],
	   CONVERT(DECIMAL (10,0), AVG(CONVERT(DECIMAL (10,0), PageLifeExpectancy))) AS [Avg Page Life Expectancy]
FROM dbo.SQLServerInstanceMetricHistory WITH (NOLOCK);



-- Get MAX for all metrics
SELECT MAX(AvgTaskCount) AS [Max Task Count],
       MAX(AvgRunnableTaskCount) AS [Max Runnable Task Count],
	   MAX(AvgPendingIOCount) AS [Max Pending IO Count],
	   MAX(SQLServerCPUUtilization) AS [Max CPU Utilization],
	   CONVERT(DECIMAL (10,0), MAX(CONVERT(DECIMAL (10,0), PageLifeExpectancy))) AS [Max Page Life Expectancy]
FROM dbo.SQLServerInstanceMetricHistory WITH (NOLOCK);



-- Get MIN for all metrics
SELECT MIN(AvgTaskCount) AS [Min Task Count],
       MIN(AvgRunnableTaskCount) AS [Min Runnable Task Count],
	   MIN(AvgPendingIOCount) AS [Min Pending IO Count],
	   MIN(SQLServerCPUUtilization) AS [Min CPU Utilization],
	   CONVERT(DECIMAL (10,0), MIN(CONVERT(DECIMAL (10,0), PageLifeExpectancy))) AS [Min Page Life Expectancy]
FROM dbo.SQLServerInstanceMetricHistory WITH (NOLOCK);


-- Look for rows where AvgPendingIOCount is > 0
SELECT AvgPendingIOCount, MeasurementTime, AvgTaskCount, 
AvgRunnableTaskCount, SQLServerCPUUtilization, PageLifeExpectancy
FROM dbo.SQLServerInstanceMetricHistory WITH (NOLOCK)
WHERE AvgPendingIOCount > 0
ORDER BY AvgPendingIOCount DESC;