-- ci: skip (T-SQL, plays on SQL Server)
-- Module V4, SQL Server side, cleanup: drops MV4PgIndex. PachaDataFormation was only read.
SET NOCOUNT ON;
IF DB_ID(N'MV4PgIndex') IS NOT NULL
BEGIN
    ALTER DATABASE MV4PgIndex SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE MV4PgIndex;
END;
SELECT COUNT(*) AS mv4_databases FROM sys.databases WHERE name LIKE N'MV4%';
GO
