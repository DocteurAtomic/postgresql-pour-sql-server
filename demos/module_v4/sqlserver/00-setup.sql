-- ci: skip (T-SQL, plays on SQL Server)
-- Module V4, SQL Server side, setup (recorded on SQL Server 2022, sqlcmd). Creates the
-- database MV4PgIndex with copies of Contact.Contact and Inscription.Facture from
-- PachaDataFormation, which is only read, and the two indexes of clips V4.3 and V4.5.
-- 99-cleanup.sql drops it.
SET NOCOUNT ON;
IF DB_ID(N'MV4PgIndex') IS NOT NULL
BEGIN
    ALTER DATABASE MV4PgIndex SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE MV4PgIndex;
END;
CREATE DATABASE MV4PgIndex;
GO
USE MV4PgIndex;
SELECT ContactId, Nom, Email INTO dbo.Contact FROM PachaDataFormation.Contact.Contact;
ALTER TABLE dbo.Contact ADD CONSTRAINT PK_Contact PRIMARY KEY (ContactId);
CREATE INDEX IX_Contact_Email ON dbo.Contact (Email);

SELECT FactureCd, DateFacture, Relance, MontantTTC INTO dbo.Facture
FROM PachaDataFormation.Inscription.Facture;
ALTER TABLE dbo.Facture ADD CONSTRAINT PK_Facture PRIMARY KEY (FactureCd);
CREATE INDEX IX_Facture_Relance_DateFacture ON dbo.Facture (Relance, DateFacture);

-- SELECT INTO keeps the collation of the source column, French_CI_AS.
SELECT (SELECT collation_name FROM sys.columns
        WHERE object_id = OBJECT_ID(N'dbo.Contact') AND name = N'Email') AS email_collation,
       (SELECT COUNT(*) FROM dbo.Contact) AS contacts,
       (SELECT COUNT(*) FROM dbo.Facture) AS factures,
       (SELECT COUNT(DISTINCT Relance) FROM dbo.Facture) AS relance_values;
GO
