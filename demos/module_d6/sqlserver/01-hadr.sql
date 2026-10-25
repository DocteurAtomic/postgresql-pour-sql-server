-- ci: skip (T-SQL, plays on SQL Server)
-- Clip D6.1, SQL Server side (recorded on SQL Server 2022, sqlcmd, read only). An instance
-- on its own: Always On availability groups not enabled, no group, no replica. An
-- availability group is a set of databases, each in the full recovery model.
SET NOCOUNT ON;
SELECT SERVERPROPERTY('IsHadrEnabled') AS is_hadr_enabled,
       SERVERPROPERTY('IsClustered') AS is_clustered,
       (SELECT COUNT(*) FROM sys.availability_groups) AS availability_groups,
       (SELECT COUNT(*) FROM sys.availability_replicas) AS replicas,
       (SELECT COUNT(*) FROM sys.dm_hadr_database_replica_states) AS database_replicas;
SELECT name, recovery_model_desc, group_database_id
FROM sys.databases
WHERE name = N'PachaDataFormation';
