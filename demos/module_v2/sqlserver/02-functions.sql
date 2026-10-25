-- ci: skip (T-SQL, plays on SQL Server)
-- Clip V2.2, SQL Server side: the functions of PachaDataFormation, and scalar UDF inlining.
-- Read only, in PachaDataFormation (sqlcmd).
SET NOCOUNT ON;
SELECT OBJECT_SCHEMA_NAME(m.object_id) + '.' + OBJECT_NAME(m.object_id) AS function_name,
       o.type_desc, m.is_inlineable
FROM sys.sql_modules AS m
JOIN sys.objects AS o ON o.object_id = m.object_id
WHERE OBJECT_NAME(m.object_id) LIKE N'GetNbInscriptions%'
ORDER BY function_name;
SELECT compatibility_level FROM sys.databases WHERE name = DB_NAME();
GO
