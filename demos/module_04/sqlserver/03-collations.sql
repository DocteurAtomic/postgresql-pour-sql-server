-- Clip 4.3, SQL Server side: the collation of the database, case-insensitive and accent-sensitive.
-- Read only, in PachaDataFormation (recorded on SQL Server 2022, sqlcmd).
SET NOCOUNT ON;
SELECT DATABASEPROPERTYEX(DB_NAME(), 'Collation') AS database_collation;
SELECT CASE WHEN 'SQL' = 'sql' THEN 'equal' ELSE 'different' END AS case_compare,
       CASE WHEN N'Élise' = N'élise' THEN 'equal' ELSE 'different' END AS case_with_accent,
       CASE WHEN N'Élise' = N'elise' THEN 'equal' ELSE 'different' END AS accent_compare;
SELECT CASE WHEN N'Élise' = N'elise' COLLATE French_CI_AI THEN 'equal' ELSE 'different' END AS with_ci_ai;
