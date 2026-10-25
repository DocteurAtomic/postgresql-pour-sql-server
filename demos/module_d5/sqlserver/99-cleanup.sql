-- ci: skip (T-SQL, plays on SQL Server)
-- Module D5, SQL Server side, cleanup: drops MD5PgMonitor.
IF DB_ID(N'MD5PgMonitor') IS NOT NULL
BEGIN
    ALTER DATABASE MD5PgMonitor SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE MD5PgMonitor;
END;
SELECT COUNT(*) AS md5_databases FROM sys.databases WHERE name = N'MD5PgMonitor';
GO
