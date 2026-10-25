-- Clip 2.4, SQL Server side: the files of a database, declared and named by the DBA.
-- Read only, in PachaDataFormation (recorded on SQL Server 2022, sqlcmd).
SET NOCOUNT ON;
SELECT file_id, type_desc, name, physical_name, size * 8 / 1024 AS size_mb
FROM sys.database_files
ORDER BY file_id;
