-- ci: skip (T-SQL, plays on SQL Server)
-- Clip 3.4, SQL Server side: the locks of an UPDATE, before and after lock escalation.
-- Recorded on SQL Server 2022 (sqlcmd), after 00-setup.sql; both transactions roll back.
USE M03PgRcsi;
SET NOCOUNT ON;
-- 3,000 rows: one KEY lock per row, under IX locks on the pages and the table.
BEGIN TRAN;
UPDATE dbo.Session SET Prix = Prix WHERE SessionId <= 3000;
SELECT resource_type, request_mode, COUNT(*) AS locks,
       COUNT(DISTINCT resource_lock_partition) AS lock_partitions
FROM sys.dm_tran_locks
WHERE request_session_id = @@SPID AND resource_database_id = DB_ID()
GROUP BY resource_type, request_mode
ORDER BY resource_type;
ROLLBACK;
-- Every row: past 5,000 locks, the engine escalates to one X lock on the table, which an
-- instance with many CPUs takes on each of its lock partitions.
BEGIN TRAN;
UPDATE dbo.Session SET Prix = Prix;
SELECT resource_type, request_mode, COUNT(*) AS locks,
       COUNT(DISTINCT resource_lock_partition) AS lock_partitions
FROM sys.dm_tran_locks
WHERE request_session_id = @@SPID AND resource_database_id = DB_ID()
GROUP BY resource_type, request_mode
ORDER BY resource_type;
ROLLBACK;
GO
