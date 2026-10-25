-- ci: skip (T-SQL, plays on SQL Server)
-- Module V5, SQL Server side, cleanup: drops MV5PgDemo (sqlcmd).
USE master;
IF DB_ID(N'MV5PgDemo') IS NOT NULL
BEGIN
    ALTER DATABASE MV5PgDemo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE MV5PgDemo;
END;
SELECT COUNT(*) AS mv5pgdemo_left FROM sys.databases WHERE name = N'MV5PgDemo';
GO
