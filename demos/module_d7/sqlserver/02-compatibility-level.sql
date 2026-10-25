-- Clip D7.1: one engine, two behaviors, chosen database by database. SQL Server 2022
-- (sql2022), sqlcmd. Creates the module database MD7PgUpgrade; sqlserver/99-cleanup.sql
-- drops it. PachaDataFormation is not touched.
SET NOCOUNT ON;
IF DB_ID(N'MD7PgUpgrade') IS NOT NULL DROP DATABASE MD7PgUpgrade;
CREATE DATABASE MD7PgUpgrade;
GO
-- A database restored from SQL Server 2016 keeps its level 130 on a 2022 engine.
ALTER DATABASE MD7PgUpgrade SET COMPATIBILITY_LEVEL = 130;
GO
USE MD7PgUpgrade;
GO
SELECT name, compatibility_level FROM sys.databases WHERE name = N'MD7PgUpgrade';
-- GENERATE_SERIES needs level 160.
SELECT value FROM GENERATE_SERIES(1, 3);
GO
ALTER DATABASE MD7PgUpgrade SET COMPATIBILITY_LEVEL = 160;
GO
USE MD7PgUpgrade;
GO
SELECT name, compatibility_level FROM sys.databases WHERE name = N'MD7PgUpgrade';
SELECT value FROM GENERATE_SERIES(1, 3);
GO
