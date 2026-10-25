-- Clip 2.1, SQL Server side: one process, a pool of worker threads.
-- Read only, on any SQL Server instance (recorded on SQL Server 2022, sqlcmd).
SET NOCOUNT ON;
SELECT cpu_count, scheduler_count, max_workers_count
FROM sys.dm_os_sys_info;

SELECT COUNT(*) AS os_threads FROM sys.dm_os_threads;
SELECT COUNT(*) AS user_sessions FROM sys.dm_exec_sessions WHERE is_user_process = 1;

SELECT name, value_in_use
FROM sys.configurations
WHERE name IN (N'user connections', N'max worker threads')
ORDER BY name;
