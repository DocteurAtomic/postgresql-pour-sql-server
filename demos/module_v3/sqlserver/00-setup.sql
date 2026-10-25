-- ci: skip (T-SQL, plays on SQL Server)
-- Module V3, SQL Server side, setup (recorded on SQL Server 2022, sqlcmd). Creates the
-- database MV3PgTx, with READ_COMMITTED_SNAPSHOT left OFF as in a new database, and copies
-- Inscription.Inscription from PachaDataFormation, which is only read. 99-cleanup.sql drops it.
SET NOCOUNT ON;
IF DB_ID(N'MV3PgTx') IS NOT NULL
BEGIN
    ALTER DATABASE MV3PgTx SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE MV3PgTx;
END;
CREATE DATABASE MV3PgTx;
GO
USE MV3PgTx;
-- The enrollments (clips V3.1 and V3.2).
-- CAST drops the IDENTITY property: the scripts insert their own keys, as in PostgreSQL.
SELECT CAST(InscriptionId AS int) AS InscriptionId, SessionId, ContactId
INTO dbo.Inscription
FROM PachaDataFormation.Inscription.Inscription;
ALTER TABLE dbo.Inscription ALTER COLUMN InscriptionId int NOT NULL;
ALTER TABLE dbo.Inscription ADD CONSTRAINT PK_Inscription PRIMARY KEY (InscriptionId);
-- The queue of notices to send (clip V3.4): the first 370 notices not sent yet.
SELECT TOP (370) CAST(InscriptionId AS int) AS InscriptionId, SessionId, CAST('to send' AS varchar(10)) AS Status,
       CAST(NULL AS varchar(10)) AS Worker
INTO dbo.Convocation
FROM PachaDataFormation.Inscription.Inscription
WHERE ConvocationEnvoyee = 0
ORDER BY InscriptionId;
ALTER TABLE dbo.Convocation ALTER COLUMN InscriptionId int NOT NULL;
ALTER TABLE dbo.Convocation ADD CONSTRAINT PK_Convocation PRIMARY KEY (InscriptionId);
SELECT (SELECT COUNT(*) FROM dbo.Inscription) AS inscriptions,
       (SELECT COUNT(*) FROM dbo.Convocation) AS convocations,
       is_read_committed_snapshot_on AS rcsi
FROM sys.databases WHERE name = N'MV3PgTx';
GO
