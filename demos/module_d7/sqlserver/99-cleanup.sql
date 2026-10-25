-- Module D7, SQL Server cleanup (sql2022, sqlcmd): drops the module database.
SET NOCOUNT ON;
IF DB_ID(N'MD7PgUpgrade') IS NOT NULL DROP DATABASE MD7PgUpgrade;
SELECT COUNT(*) AS md7_databases FROM sys.databases WHERE name LIKE N'MD7%';
