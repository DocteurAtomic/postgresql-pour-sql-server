-- ci: skip (T-SQL, sqlcmd)
-- Clip V5.5, SQL Server side: READ_COMMITTED_SNAPSHOT in MV5PgDemo, off for the first run
-- of 05a and 05b (sqlcmd -v RCSI=OFF), on for the second (RCSI=ON), as in Azure SQL Database.
USE master;
ALTER DATABASE MV5PgDemo SET READ_COMMITTED_SNAPSHOT $(RCSI) WITH ROLLBACK IMMEDIATE;
SELECT name, is_read_committed_snapshot_on FROM sys.databases WHERE name = N'MV5PgDemo';
GO
