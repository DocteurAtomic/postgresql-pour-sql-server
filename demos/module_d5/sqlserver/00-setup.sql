-- ci: skip (T-SQL, plays on SQL Server)
-- Module D5, SQL Server side, setup (recorded on SQL Server 2022, sqlcmd). Creates the
-- database MD5PgMonitor and copies two columns of Stage.Session and Inscription.Inscription
-- from PachaDataFormation, which is only read. The scenes of the module lock and KILL
-- sessions in this database only. The Query Store captures every query (clip D5.4).
-- 99-cleanup.sql drops the database.
SET NOCOUNT ON;
IF DB_ID(N'MD5PgMonitor') IS NOT NULL
BEGIN
    ALTER DATABASE MD5PgMonitor SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE MD5PgMonitor;
END;
CREATE DATABASE MD5PgMonitor;
GO
ALTER DATABASE MD5PgMonitor SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = ALL);
GO
USE MD5PgMonitor;
SELECT SessionId, StageId, DateDebut, Prix
INTO dbo.Session
FROM PachaDataFormation.Stage.Session;
ALTER TABLE dbo.Session ADD CONSTRAINT PK_Session PRIMARY KEY (SessionId);
SELECT InscriptionId, ContactId
INTO dbo.Inscription
FROM PachaDataFormation.Inscription.Inscription;
SELECT (SELECT COUNT(*) FROM dbo.Session) AS sessions,
       (SELECT COUNT(*) FROM dbo.Inscription) AS inscriptions,
       (SELECT is_read_committed_snapshot_on FROM sys.databases WHERE name = N'MD5PgMonitor') AS rcsi,
       (SELECT actual_state_desc FROM sys.database_query_store_options) AS query_store;
GO
