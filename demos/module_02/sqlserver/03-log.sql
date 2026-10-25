-- Clip 2.3, SQL Server side: one transaction log per database, a recovery model per database.
-- Read only (recorded on SQL Server 2022, sqlcmd).
SET NOCOUNT ON;
SELECT name, recovery_model_desc, target_recovery_time_in_seconds
FROM sys.databases
WHERE database_id <= 4 OR name = N'PachaDataFormation'
ORDER BY database_id;

SELECT DB_NAME(database_id) AS database_name, name, physical_name
FROM sys.master_files
WHERE type_desc = N'LOG' AND (database_id <= 4 OR DB_NAME(database_id) = N'PachaDataFormation')
ORDER BY database_id;
