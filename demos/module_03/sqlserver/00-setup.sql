-- ci: skip (T-SQL, plays on SQL Server)
-- Module 3, SQL Server side, setup (recorded on SQL Server 2022, sqlcmd). Creates the
-- database M03PgRcsi and copies Stage.Session from PachaDataFormation, which is only read.
-- READ_COMMITTED_SNAPSHOT stays OFF, the default of a new database. 99-cleanup.sql drops it.
SET NOCOUNT ON;
IF DB_ID(N'M03PgRcsi') IS NOT NULL
BEGIN
    ALTER DATABASE M03PgRcsi SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE M03PgRcsi;
END;
CREATE DATABASE M03PgRcsi;
GO
USE M03PgRcsi;
SELECT SessionId, StageId, DateDebut, Prix
INTO dbo.Session
FROM PachaDataFormation.Stage.Session;
ALTER TABLE dbo.Session ADD CONSTRAINT PK_Session PRIMARY KEY (SessionId);
SELECT COUNT(*) AS sessions FROM dbo.Session;
GO
