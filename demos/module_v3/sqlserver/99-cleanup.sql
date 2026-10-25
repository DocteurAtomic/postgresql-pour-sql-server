-- ci: skip (T-SQL, plays on SQL Server)
-- Module V3, SQL Server side, cleanup: drops MV3PgTx. PachaDataFormation was only read.
SET NOCOUNT ON;
IF DB_ID(N'MV3PgTx') IS NOT NULL
BEGIN
    ALTER DATABASE MV3PgTx SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE MV3PgTx;
END;
SELECT COUNT(*) AS mv3_databases FROM sys.databases WHERE name LIKE N'MV3%';
GO
