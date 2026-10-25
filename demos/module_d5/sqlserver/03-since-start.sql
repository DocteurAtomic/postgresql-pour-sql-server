-- ci: skip (T-SQL, plays on SQL Server)
-- Clip D5.3, SQL Server side, read only on PachaDataFormation: the DMVs count since the
-- start of the instance; sys.dm_db_index_usage_stats has no row for an index not used since.
SET NOCOUNT ON;
USE PachaDataFormation;
SELECT sqlserver_start_time FROM sys.dm_os_sys_info;
SELECT i.name AS index_name, u.user_seeks, u.user_scans, u.user_updates,
       u.last_user_seek, u.last_user_scan
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats u
       ON u.object_id = i.object_id AND u.index_id = i.index_id AND u.database_id = DB_ID()
WHERE i.object_id = OBJECT_ID(N'Inscription.Facture')
ORDER BY i.index_id;
GO
