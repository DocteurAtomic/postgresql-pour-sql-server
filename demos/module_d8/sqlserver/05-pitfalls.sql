-- Clip D8.5: four checks that do not compare across engines. SQL Server 2022 (sql2022),
-- sqlcmd, database PachaDataFormation, read only. 05-pitfalls.sql asks the same in PostgreSQL.
SET NOCOUNT ON;
-- 1. A hash of the same name: MD5 of the bytes, in the code page of the column (1252).
SELECT HASHBYTES('MD5', NomVille) AS md5, DATALENGTH(NomVille) AS bytes, LEN(NomVille) AS characters
FROM Reference.ville WHERE VilleId = 1;
-- 2. Distinct values under the collation of the database (French_CI_AS: case-insensitive).
SELECT COUNT(DISTINCT Nom) AS ci_as, COUNT(DISTINCT Nom COLLATE Latin1_General_BIN2) AS bin2
FROM Contact.Contact;
-- 3. The smallest e-mail address, by collation.
SELECT MIN(Email) AS ci_as, MIN(Email COLLATE Latin1_General_BIN2) AS bin2 FROM Contact.Contact;
-- 4. A char(10): LEN() drops the trailing blanks, DATALENGTH() counts them.
SELECT TOP (1) Statut, LEN(Statut) AS len, DATALENGTH(Statut) AS datalength
FROM Stage.Session WHERE Statut = 'TERMINEE';
