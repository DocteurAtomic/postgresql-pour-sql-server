-- Clip 2.5, SQL Server side: a three-part name crosses databases, model is the template.
-- Read only, in PachaDataFormation (recorded on SQL Server 2022, sqlcmd).
SET NOCOUNT ON;
SELECT DB_NAME() AS current_database;
SELECT COUNT(*) AS master_objects FROM master.sys.objects;
SELECT name, SCHEMA_NAME() AS default_schema
FROM sys.database_principals
WHERE name = USER_NAME();
SELECT name, database_id FROM sys.databases WHERE name IN (N'model', N'tempdb') ORDER BY database_id;
