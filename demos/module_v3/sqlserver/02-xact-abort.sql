-- ci: skip (T-SQL, plays on SQL Server)
-- Clip V3.2, SQL Server side, database MV3PgTx: the same transaction as
-- 02-aborted-transaction.sql, with XACT_ABORT OFF (the default) then ON. 100 already exists.
-- No SET NOCOUNT ON here: with it, sqlcmd 18 stops reading the results of the third
-- batch after the error ("SqlState 24000, Invalid cursor state").
SET NOCOUNT OFF;
USE MV3PgTx;
SET XACT_ABORT OFF;
BEGIN TRAN;
INSERT INTO dbo.Inscription (InscriptionId, SessionId) VALUES (900001, 41);
INSERT INTO dbo.Inscription (InscriptionId, SessionId) VALUES (100, 41);
SELECT @@TRANCOUNT AS trancount, XACT_STATE() AS xact_state;
COMMIT;
SELECT COUNT(*) AS kept_rows FROM dbo.Inscription WHERE InscriptionId = 900001;
DELETE FROM dbo.Inscription WHERE InscriptionId >= 900000;
GO
SET XACT_ABORT ON;
BEGIN TRAN;
INSERT INTO dbo.Inscription (InscriptionId, SessionId) VALUES (900001, 41);
INSERT INTO dbo.Inscription (InscriptionId, SessionId) VALUES (100, 41);
SELECT @@TRANCOUNT AS trancount_not_reached;   -- the batch stops at the error
COMMIT;
GO
SELECT @@TRANCOUNT AS trancount, COUNT(*) AS kept_rows
FROM dbo.Inscription WHERE InscriptionId = 900001;
GO
-- 3. SAVE TRANSACTION, the savepoint of SQL Server.
SET XACT_ABORT OFF;
BEGIN TRAN;
INSERT INTO dbo.Inscription (InscriptionId, SessionId) VALUES (900001, 41);
SAVE TRANSACTION before_second;
INSERT INTO dbo.Inscription (InscriptionId, SessionId) VALUES (100, 41);
ROLLBACK TRANSACTION before_second;
INSERT INTO dbo.Inscription (InscriptionId, SessionId) VALUES (900002, 41);
COMMIT;
SELECT InscriptionId FROM dbo.Inscription WHERE InscriptionId >= 900000 ORDER BY InscriptionId;
DELETE FROM dbo.Inscription WHERE InscriptionId >= 900000;
GO
