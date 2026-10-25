-- ci: skip (T-SQL, plays on SQL Server)
-- Module V6, SQL Server side, clips V6.2 and V6.3 (recorded on SQL Server 2022 CU26, sqlcmd,
-- database PachaDataFormation, read only). Its data is not the data of the port: compare
-- the behaviour, not the counts.
SET NOCOUNT ON;

-- 1. Full-text search is a separate component, not installed in this container.
SELECT SERVERPROPERTY('IsFullTextInstalled') AS full_text_installed;

-- 2. SOUNDEX and DIFFERENCE.
SELECT SOUNDEX('Lefebvre') AS lefebvre, SOUNDEX('Lefevre') AS lefevre,
       DIFFERENCE('Lefebvre', 'Lefevre') AS difference;
SELECT SOUNDEX('Elise') AS elise, SOUNDEX(N'Élise') AS elise_accent;
SELECT COUNT(DISTINCT Nom) AS same_soundex
FROM Contact.Contact
WHERE SOUNDEX(Nom) = SOUNDEX('Lefevre');

-- 3. Accents: the collation of the database, then an accent-insensitive one.
SELECT DATABASEPROPERTYEX(DB_NAME(), 'Collation') AS database_collation;
SELECT COUNT(*) AS helene_ci_as FROM Contact.Contact WHERE Prenom = 'helene';
SELECT COUNT(*) AS helene_ci_ai FROM Contact.Contact WHERE Prenom = 'helene' COLLATE French_CI_AI;
