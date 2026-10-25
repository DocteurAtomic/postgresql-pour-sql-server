-- Clip D3.4: log backups and RESTORE ... WITH STOPAT. SQL Server 2022, after
-- 03-backup-database.sql, in MD3PgBackup; the restore goes to a new database,
-- MD3PgBackupRestore, never over an existing one. One batch, to keep the variable @mark.
SET NOCOUNT ON;
DECLARE @mark datetime, @rows int;
BACKUP LOG MD3PgBackup TO DISK = N'/var/opt/mssql/backup/md3_log1.trn' WITH INIT, FORMAT;

-- a legitimate change, then the moment to go back to, then the mistake
UPDATE MD3PgBackup.dbo.Session SET Prix = Prix * 1.05 WHERE DateDebut >= '2020-01-01';
SET @rows = @@ROWCOUNT;
WAITFOR DELAY '00:00:01';
SET @mark = GETDATE();
WAITFOR DELAY '00:00:01';
DELETE FROM MD3PgBackup.dbo.SuiviFacture;          -- no WHERE clause
SELECT @rows AS sessions_updated, @mark AS stop_at, @@ROWCOUNT AS deleted_by_mistake;

BACKUP LOG MD3PgBackup TO DISK = N'/var/opt/mssql/backup/md3_log2.trn' WITH INIT, FORMAT;

RESTORE DATABASE MD3PgBackupRestore FROM DISK = N'/var/opt/mssql/backup/md3_full.bak'
    WITH MOVE N'MD3PgBackup' TO N'/var/opt/mssql/data/MD3PgBackupRestore.mdf',
         MOVE N'MD3PgBackup_log' TO N'/var/opt/mssql/data/MD3PgBackupRestore_log.ldf',
         NORECOVERY;
RESTORE LOG MD3PgBackupRestore FROM DISK = N'/var/opt/mssql/backup/md3_log1.trn' WITH NORECOVERY;
RESTORE LOG MD3PgBackupRestore FROM DISK = N'/var/opt/mssql/backup/md3_log2.trn'
    WITH STOPAT = @mark, RECOVERY;

SELECT N'MD3PgBackup' AS db, (SELECT COUNT(*) FROM MD3PgBackup.dbo.SuiviFacture) AS suivifacture,
       (SELECT COUNT(*) FROM MD3PgBackup.dbo.Session WHERE DateDebut >= '2020-01-01'
          AND Prix <> (SELECT s.Prix FROM PachaDataFormation.Stage.Session s
                       WHERE s.SessionId = MD3PgBackup.dbo.Session.SessionId)) AS prices_raised
UNION ALL
SELECT N'MD3PgBackupRestore', (SELECT COUNT(*) FROM MD3PgBackupRestore.dbo.SuiviFacture),
       (SELECT COUNT(*) FROM MD3PgBackupRestore.dbo.Session WHERE DateDebut >= '2020-01-01'
          AND Prix <> (SELECT s.Prix FROM PachaDataFormation.Stage.Session s
                       WHERE s.SessionId = MD3PgBackupRestore.dbo.Session.SessionId));
