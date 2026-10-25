-- ci: skip (T-SQL, plays on SQL Server)
-- Clip D5.1, SQL Server side, read only: the waits SQL Server has added up since it
-- started, a few of the waits that mean nothing set aside. Never cleared here.
SET NOCOUNT ON;
SELECT sqlserver_start_time,
       DATEDIFF(hour, sqlserver_start_time, SYSDATETIME()) AS hours_up
FROM sys.dm_os_sys_info;
SELECT TOP (5) wait_type, waiting_tasks_count,
       CAST(wait_time_ms / 1000.0 AS decimal(12, 1)) AS wait_s
FROM sys.dm_os_wait_stats
WHERE wait_type NOT LIKE N'%SLEEP%' AND wait_type NOT LIKE N'%QUEUE%'
  AND wait_type NOT LIKE N'XE[_]%' AND wait_type NOT LIKE N'HADR[_]%'
  AND wait_type NOT LIKE N'BROKER[_]%'
  AND wait_type NOT IN (N'SOS_WORK_DISPATCHER', N'DIRTY_PAGE_POLL', N'WAITFOR',
                        N'REQUEST_FOR_DEADLOCK_SEARCH', N'PWAIT_EXTENSIBILITY_CLEANUP_TASK',
                        N'PVS_PREALLOCATE')
ORDER BY wait_time_ms DESC;
GO
