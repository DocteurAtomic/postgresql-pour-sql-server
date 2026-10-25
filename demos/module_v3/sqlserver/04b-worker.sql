-- ci: skip (T-SQL, two sessions: play it one second after 04a-worker.sql)
-- Clip V3.4, SQL Server side, database MV3PgTx, session B: the same worker takes the next
-- five rows, then the locks of both sessions, then the NOWAIT hint on the rows A holds.
SET NOCOUNT ON;
USE MV3PgTx;
BEGIN TRAN;
WITH next AS (
    SELECT TOP (5) InscriptionId, Status, Worker
    FROM dbo.Convocation WITH (ROWLOCK, UPDLOCK, READPAST)
    WHERE Status = 'to send'
    ORDER BY InscriptionId)
UPDATE next SET Status = 'sending', Worker = 'B'
OUTPUT inserted.InscriptionId, inserted.Worker;
SELECT CASE WHEN request_session_id = @@SPID THEN 'B' ELSE 'A' END AS worker,
       resource_type, request_mode, COUNT(*) AS locks
FROM sys.dm_tran_locks
WHERE resource_database_id = DB_ID() AND resource_type IN ('OBJECT', 'PAGE', 'KEY')
GROUP BY CASE WHEN request_session_id = @@SPID THEN 'B' ELSE 'A' END, resource_type, request_mode
ORDER BY worker, resource_type;
ROLLBACK;
GO
BEGIN TRAN;
SELECT TOP (5) InscriptionId
FROM dbo.Convocation WITH (UPDLOCK, NOWAIT)
WHERE Status = 'to send'
ORDER BY InscriptionId;
GO
IF @@TRANCOUNT > 0 ROLLBACK;
GO
