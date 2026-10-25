-- ci: skip (T-SQL, plays on SQL Server)
-- Module V7, SQL Server side, setup (recorded on SQL Server 2022, sqlcmd -I). Creates the
-- database MV7PgSniff, compatibility level 160, and two tables. PachaDataFormation is only read.
-- 99-cleanup.sql drops the database.
SET NOCOUNT ON;
IF DB_ID(N'MV7PgSniff') IS NOT NULL
BEGIN
    ALTER DATABASE MV7PgSniff SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE MV7PgSniff;
END;
CREATE DATABASE MV7PgSniff;
ALTER DATABASE MV7PgSniff SET COMPATIBILITY_LEVEL = 160;
GO
USE MV7PgSniff;
-- dbo.Facture: 16 514 invoices of PachaDataFormation, with a Relance column shaped like the
-- PostgreSQL port's (6 533 at 0, the rest spread over 255 values), and an index on it.
-- The data of SQL Server is not the port's: Relance is recomputed, not copied.
WITH n AS (
    SELECT TOP (16514) ROW_NUMBER() OVER (ORDER BY FactureCd) AS rn, f.*
    FROM PachaDataFormation.Inscription.Facture AS f)
SELECT CAST(FactureCd AS varchar(50)) AS FactureCd,
       CAST(CASE WHEN rn <= 6533 THEN 0 ELSE 1 + rn % 255 END AS smallint) AS Relance,
       MontantTTC, MontantHT, DateCreation, DateFacture, ReferenceCommande, CodeRemise, Remise, TauxTVA
INTO dbo.Facture
FROM n;
ALTER TABLE dbo.Facture ALTER COLUMN FactureCd varchar(50) NOT NULL;
ALTER TABLE dbo.Facture ADD CONSTRAINT PK_Facture PRIMARY KEY (FactureCd);
CREATE INDEX IX_Facture_Relance ON dbo.Facture (Relance);
-- dbo.Skewed: two million rows, 1 990 000 at K = 0 and ten for each of 1 000 other values,
-- for the Parameter Sensitive Plan optimization of clip V7.3.
SELECT TOP (2000000)
       CAST(CASE WHEN ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) <= 1990000 THEN 0
                 ELSE 1 + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) % 1000 END AS int) AS K,
       CAST('x' AS char(200)) AS Filler
INTO dbo.Skewed
FROM sys.all_columns AS a CROSS JOIN sys.all_columns AS b;
CREATE INDEX IX_Skewed_K ON dbo.Skewed (K);
UPDATE STATISTICS dbo.Skewed WITH FULLSCAN;
SELECT (SELECT COUNT(*) FROM dbo.Facture) AS factures,
       (SELECT COUNT(*) FROM dbo.Facture WHERE Relance = 0) AS relance_0,
       (SELECT COUNT(*) FROM dbo.Skewed) AS skewed,
       compatibility_level, is_query_store_on
FROM sys.databases WHERE name = N'MV7PgSniff';
GO
