-- Clip D3.3: BACKUP DATABASE, one database at a time. SQL Server 2022, in a database of the
-- module, MD3PgBackup, made of copies of two tables of PachaDataFormation (which is never
-- backed up or changed here). sqlserver/99-cleanup.sql drops it; the .bak files go with it.
SET NOCOUNT ON;
CREATE DATABASE MD3PgBackup;
ALTER DATABASE MD3PgBackup SET RECOVERY FULL;
GO
SELECT * INTO MD3PgBackup.dbo.Session FROM PachaDataFormation.Stage.Session;
SELECT * INTO MD3PgBackup.dbo.SuiviFacture FROM PachaDataFormation.Inscription.SuiviFacture;
GO
BACKUP DATABASE MD3PgBackup TO DISK = N'/var/opt/mssql/backup/md3_full.bak'
    WITH INIT, FORMAT, CHECKSUM, STATS = 100;
GO
SELECT database_name, type, CAST(backup_size / 1048576.0 AS decimal(6,1)) AS size_mb,
       first_lsn, last_lsn, recovery_model
FROM msdb.dbo.backupset
WHERE database_name = N'MD3PgBackup'
ORDER BY backup_set_id;
