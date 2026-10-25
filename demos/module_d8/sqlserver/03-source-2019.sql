-- Clip D8.3: the traces of the lab database, looked for in its SQL Server source. Played on
-- the public 2019 backup of PachaDataFormation, which exercises/module_d8/1-start.sh restores
-- in the container pgd8-exsql (sqlcmd, read only). The lab database has the same 30,436
-- registrations; the regenerated database of sql2022 does not.
SET NOCOUNT ON;
SELECT COUNT(*) AS inscriptions,
       SUM(CASE WHEN s.SessionId IS NULL THEN 1 ELSE 0 END) AS without_session,
       SUM(CASE WHEN i.ContactId IS NULL THEN 1 ELSE 0 END) AS without_contact
FROM Inscription.Inscription AS i
LEFT JOIN Stage.Session AS s ON s.SessionId = i.SessionId;
SELECT name AS foreign_key FROM sys.foreign_keys WHERE parent_object_id = OBJECT_ID('Inscription.Inscription');
SELECT SUM(CASE WHEN CodeRemise IS NOT NULL AND LTRIM(CodeRemise) = '' THEN 1 ELSE 0 END) AS blank_codes
FROM Inscription.Facture;
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE (TABLE_NAME = 'Formateur' AND COLUMN_NAME = 'CreationUser')
   OR (TABLE_NAME = 'Ville' AND COLUMN_NAME = 'CodeINSEE');
-- The other traces: the index named after the SSMS template, the four relance indexes, the
-- table facturecolumnstore.
SELECT OBJECT_NAME(object_id) AS table_name, name AS index_name
FROM sys.indexes
WHERE object_id IN (OBJECT_ID('Inscription.Inscription'), OBJECT_ID('Inscription.Facture')) AND name IS NOT NULL
ORDER BY 1, 2;
SELECT COUNT(*) AS columnstore_tables FROM sys.tables WHERE name LIKE '%columnstore%';
