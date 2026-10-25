-- ci: skip (T-SQL, plays on SQL Server)
-- Clip 3.2, SQL Server side: READ_COMMITTED_SNAPSHOT ON. Run it, then 02a and 02b again.
ALTER DATABASE M03PgRcsi SET READ_COMMITTED_SNAPSHOT ON WITH ROLLBACK IMMEDIATE;
SELECT name, is_read_committed_snapshot_on FROM sys.databases WHERE name = N'M03PgRcsi';
GO
