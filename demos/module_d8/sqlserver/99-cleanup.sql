-- Module D8, SQL Server cleanup (sql2022, sqlcmd): drops the database of 06-freeze.sql if a
-- run stopped before its end, and checks that no database of the module is left.
SET NOCOUNT ON;
IF DB_ID(N'MD8PgCutover') IS NOT NULL
BEGIN
    ALTER DATABASE MD8PgCutover SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE MD8PgCutover;
END;
SELECT COUNT(*) AS md8_databases FROM sys.databases WHERE name LIKE N'MD8%';
