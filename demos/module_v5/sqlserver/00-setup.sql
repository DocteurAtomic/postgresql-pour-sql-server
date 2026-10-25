-- ci: skip (T-SQL, plays on SQL Server)
-- Module V5, SQL Server side, setup (recorded on SQL Server 2022, sqlcmd). Creates the
-- database MV5PgDemo, where 05-booking-trigger.sql writes. PachaDataFormation is not
-- touched. 99-cleanup.sql drops the database.
SET NOCOUNT ON;
IF DB_ID(N'MV5PgDemo') IS NOT NULL
BEGIN
    ALTER DATABASE MV5PgDemo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE MV5PgDemo;
END;
CREATE DATABASE MV5PgDemo;
GO
SELECT name, is_read_committed_snapshot_on FROM sys.databases WHERE name = N'MV5PgDemo';
GO
