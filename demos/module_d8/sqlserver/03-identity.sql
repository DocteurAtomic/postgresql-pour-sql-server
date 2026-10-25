-- Clip D8.3: why pgloader finds no identity column outside dbo. SQL Server 2022 (sql2022),
-- sqlcmd, database PachaDataFormation, read only.
SET NOCOUNT ON;
-- Identity columns of the five schemas that the module migrates.
SELECT COUNT(*) AS identity_columns
FROM sys.identity_columns AS ic
JOIN sys.tables AS t ON t.object_id = ic.object_id
WHERE SCHEMA_NAME(t.schema_id) IN ('Stage', 'Inscription', 'Formateur', 'Contact', 'Reference')
  AND t.name NOT IN ('ville', 'Region');
-- pgloader 3.6 reads COLUMNPROPERTY(object_id(TABLE_NAME), ...): a table name without its
-- schema resolves in the default schema of the login (dbo), not in Stage.
SELECT COLUMNPROPERTY(OBJECT_ID('Session'), 'SessionId', 'IsIdentity') AS name_only,
       COLUMNPROPERTY(OBJECT_ID('Stage.Session'), 'SessionId', 'IsIdentity') AS schema_and_name;
