-- ci: skip (T-SQL, plays on SQL Server)
-- Clip D5.4, SQL Server side, in MD5PgMonitor (00-setup.sql, Query Store on, capture ALL):
-- the same query run three times with three values, then what the Query Store keeps: the
-- query, its text, its plan and the runtime statistics by interval, in the database.
SET NOCOUNT ON;
EXEC sys.sp_query_store_flush_db;
DECLARE @stage int;
EXEC sp_executesql N'SELECT COUNT(*) FROM dbo.Session WHERE StageId = @s', N'@s int', @s = 1;
EXEC sp_executesql N'SELECT COUNT(*) FROM dbo.Session WHERE StageId = @s', N'@s int', @s = 2;
EXEC sp_executesql N'SELECT COUNT(*) FROM dbo.Session WHERE StageId = @s', N'@s int', @s = 3;
EXEC sys.sp_query_store_flush_db;
SELECT q.query_id, p.plan_id, rs.count_executions,
       CAST(rs.avg_duration / 1000.0 AS decimal(10, 2)) AS avg_ms,
       i.start_time AS interval_start, p.is_forced_plan,
       DATALENGTH(p.query_plan) AS plan_bytes,
       LEFT(t.query_sql_text, 50) AS query_text
FROM sys.query_store_query q
JOIN sys.query_store_query_text t ON t.query_text_id = q.query_text_id
JOIN sys.query_store_plan p ON p.query_id = q.query_id
JOIN sys.query_store_runtime_stats rs ON rs.plan_id = p.plan_id
JOIN sys.query_store_runtime_stats_interval i
  ON i.runtime_stats_interval_id = rs.runtime_stats_interval_id
WHERE t.query_sql_text LIKE N'(@s int)SELECT COUNT(*) FROM dbo.Session%';
-- A plan can be forced, which pg_stat_statements has no notion of.
DECLARE @q bigint, @p bigint;
SELECT TOP (1) @q = q.query_id, @p = p.plan_id
FROM sys.query_store_query q
JOIN sys.query_store_query_text t ON t.query_text_id = q.query_text_id
JOIN sys.query_store_plan p ON p.query_id = q.query_id
WHERE t.query_sql_text LIKE N'(@s int)SELECT COUNT(*) FROM dbo.Session%';
EXEC sys.sp_query_store_force_plan @query_id = @q, @plan_id = @p;
SELECT plan_id, is_forced_plan FROM sys.query_store_plan WHERE plan_id = @p;
EXEC sys.sp_query_store_unforce_plan @query_id = @q, @plan_id = @p;
SELECT actual_state_desc, interval_length_minutes, stale_query_threshold_days,
       max_storage_size_mb
FROM sys.database_query_store_options;
GO
