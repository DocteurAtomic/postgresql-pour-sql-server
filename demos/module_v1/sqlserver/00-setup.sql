-- ci: skip (T-SQL, plays on SQL Server)
-- Module V1, SQL Server side, setup (recorded on SQL Server 2022, sqlcmd). Creates the
-- database MV1PgDml and copies Stage.Session from PachaDataFormation, which is only read,
-- for the scripts that write (clips V1.4 to V1.6). 99-cleanup.sql drops it.
SET NOCOUNT ON;
IF DB_ID(N'MV1PgDml') IS NOT NULL
BEGIN
    ALTER DATABASE MV1PgDml SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE MV1PgDml;
END;
CREATE DATABASE MV1PgDml;
GO
USE MV1PgDml;
-- SELECT INTO keeps the IDENTITY property of SessionId.
SELECT SessionId, StageId, LangueCd, DateDebut, Prix
INTO dbo.Session
FROM PachaDataFormation.Stage.Session;
ALTER TABLE dbo.Session ADD CONSTRAINT PK_Session PRIMARY KEY (SessionId);
SELECT COUNT(*) AS sessions, COLUMNPROPERTY(OBJECT_ID(N'dbo.Session'), 'SessionId', 'IsIdentity') AS is_identity
FROM dbo.Session;
GO
