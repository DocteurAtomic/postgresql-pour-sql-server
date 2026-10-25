-- ci: skip (T-SQL, plays on SQL Server)
-- Clip 3.2, SQL Server side: READ_COMMITTED_SNAPSHOT OFF, the default of a new database
-- outside Azure SQL Database. Run it, then the two sessions 02a and 02b.
ALTER DATABASE M03PgRcsi SET READ_COMMITTED_SNAPSHOT OFF WITH ROLLBACK IMMEDIATE;
SELECT name, is_read_committed_snapshot_on FROM sys.databases WHERE name = N'M03PgRcsi';
GO
