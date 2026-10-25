-- ci: skip (T-SQL, plays on SQL Server)
-- Module V1, SQL Server side, cleanup: drops MV1PgDml. PachaDataFormation was only read.
SET NOCOUNT ON;
IF DB_ID(N'MV1PgDml') IS NOT NULL
BEGIN
    ALTER DATABASE MV1PgDml SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE MV1PgDml;
END;
SELECT COUNT(*) AS mv1_databases FROM sys.databases WHERE name LIKE N'MV1%';
GO
