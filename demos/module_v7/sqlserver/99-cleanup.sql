-- ci: skip (T-SQL, plays on SQL Server)
-- Module V7, SQL Server side, cleanup: drops MV7PgSniff.
SET NOCOUNT ON;
IF DB_ID(N'MV7PgSniff') IS NOT NULL
BEGIN
    ALTER DATABASE MV7PgSniff SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE MV7PgSniff;
END;
SELECT COUNT(*) AS mv7_databases FROM sys.databases WHERE name LIKE N'MV7%';
GO
