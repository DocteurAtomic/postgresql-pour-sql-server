-- ci: skip (T-SQL, two sessions: play it with 04b-worker.sql, B one second after A)
-- Clip V3.4, SQL Server side, database MV3PgTx, session A: the worker of a queue in
-- SQL Server, READPAST with UPDLOCK and ROWLOCK. It keeps its five rows six seconds.
SET NOCOUNT ON;
USE MV3PgTx;
UPDATE dbo.Convocation SET Status = 'to send', Worker = NULL;
BEGIN TRAN;
WITH next AS (
    SELECT TOP (5) InscriptionId, Status, Worker
    FROM dbo.Convocation WITH (ROWLOCK, UPDLOCK, READPAST)
    WHERE Status = 'to send'
    ORDER BY InscriptionId)
UPDATE next SET Status = 'sending', Worker = 'A'
OUTPUT inserted.InscriptionId, inserted.Worker;
WAITFOR DELAY '00:00:06';
COMMIT;
GO
