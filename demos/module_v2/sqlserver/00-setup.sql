-- ci: skip (T-SQL, plays on SQL Server)
-- Module V2, SQL Server side, setup (recorded on SQL Server 2022, sqlcmd). Creates the
-- database MV2PgDemo and copies the columns it needs from Contact.Contact of
-- PachaDataFormation, which is only read. 99-cleanup.sql drops it.
SET NOCOUNT ON;
IF DB_ID(N'MV2PgDemo') IS NOT NULL
BEGIN
    ALTER DATABASE MV2PgDemo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE MV2PgDemo;
END;
CREATE DATABASE MV2PgDemo;
GO
USE MV2PgDemo;
SET NOCOUNT ON;
SELECT ContactId, Nom, Prenom, Email
INTO dbo.Contact
FROM PachaDataFormation.Contact.Contact;
ALTER TABLE dbo.Contact ADD CONSTRAINT PK_Contact PRIMARY KEY (ContactId);
CREATE TABLE dbo.Log (Id int CONSTRAINT PK_Log PRIMARY KEY, Label varchar(50));
INSERT INTO dbo.Log VALUES (1, 'existing');
SELECT COUNT(*) AS contacts FROM dbo.Contact;
GO
