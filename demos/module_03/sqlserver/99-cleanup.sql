-- ci: skip (T-SQL, plays on SQL Server)
-- Module 3, SQL Server side, cleanup: drops M03PgRcsi.
IF DB_ID(N'M03PgRcsi') IS NOT NULL
BEGIN
    ALTER DATABASE M03PgRcsi SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE M03PgRcsi;
END;
SELECT COUNT(*) AS m03_databases FROM sys.databases WHERE name = N'M03PgRcsi';
GO
