-- ci: skip (T-SQL, plays on SQL Server)
-- Clip 3.1, SQL Server side: where the row versions go under READ_COMMITTED_SNAPSHOT.
-- Recorded on SQL Server 2022 (sqlcmd), after 00-setup.sql; writes only in M03PgRcsi.
SET NOCOUNT ON;
SELECT name, is_read_committed_snapshot_on, snapshot_isolation_state_desc,
       is_accelerated_database_recovery_on
FROM sys.databases
WHERE name IN (N'PachaDataFormation', N'M03PgRcsi');
GO
ALTER DATABASE M03PgRcsi SET READ_COMMITTED_SNAPSHOT ON WITH ROLLBACK IMMEDIATE;
GO
USE M03PgRcsi;
SET NOCOUNT ON;
BEGIN TRAN;
UPDATE dbo.Session SET Prix = Prix + 100 WHERE SessionId <= 1000;
-- The previous versions of the 1,000 rows, copied to the version store of tempdb.
SELECT COUNT(*) AS versions_in_tempdb
FROM sys.dm_tran_version_store
WHERE database_id = DB_ID();
SELECT DB_NAME(database_id) AS database_name, reserved_page_count, reserved_space_kb
FROM sys.dm_tran_version_store_space_usage
WHERE database_id = DB_ID();
ROLLBACK;
GO
