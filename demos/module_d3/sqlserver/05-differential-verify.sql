-- Clip D3.5: the differential backup and RESTORE VERIFYONLY. SQL Server 2022, after
-- 04-log-stopat.sql, in MD3PgBackup.
SET NOCOUNT ON;
UPDATE MD3PgBackup.dbo.Session SET Note = Note WHERE SessionId % 10 = 0;
BACKUP DATABASE MD3PgBackup TO DISK = N'/var/opt/mssql/backup/md3_diff.bak'
    WITH DIFFERENTIAL, INIT, FORMAT, CHECKSUM;
GO
SELECT type, CAST(backup_size / 1048576.0 AS decimal(6,2)) AS size_mb,
       differential_base_lsn, first_lsn
FROM msdb.dbo.backupset
WHERE database_name = N'MD3PgBackup'
ORDER BY backup_set_id;
GO
RESTORE VERIFYONLY FROM DISK = N'/var/opt/mssql/backup/md3_full.bak' WITH CHECKSUM;
RESTORE VERIFYONLY FROM DISK = N'/var/opt/mssql/backup/md3_diff.bak' WITH CHECKSUM;
