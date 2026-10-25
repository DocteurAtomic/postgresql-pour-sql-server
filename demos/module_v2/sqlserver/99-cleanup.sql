-- ci: skip (T-SQL, plays on SQL Server)
-- Module V2, SQL Server side, cleanup: drops the database MV2PgDemo.
IF DB_ID(N'MV2PgDemo') IS NOT NULL
BEGIN
    ALTER DATABASE MV2PgDemo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE MV2PgDemo;
END;
SET NOCOUNT ON;
SELECT COUNT(*) AS mv2pgdemo_databases FROM sys.databases WHERE name = N'MV2PgDemo';
GO
