-- Module D3, SQL Server cleanup: drops the two databases of the module and their backup
-- history. The .bak and .trn files are removed from the shell:
--   podman exec sql2022 sh -c 'rm -f /var/opt/mssql/backup/md3_*'
SET NOCOUNT ON;
DROP DATABASE IF EXISTS MD3PgBackupRestore;
DROP DATABASE IF EXISTS MD3PgBackup;
EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'MD3PgBackupRestore';
EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'MD3PgBackup';
SELECT COUNT(*) AS md3_databases FROM sys.databases WHERE name LIKE N'MD3Pg%';
