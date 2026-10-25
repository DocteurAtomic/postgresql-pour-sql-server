-- ci: skip (T-SQL, two sessions: play it with 05b-applock.sql, B one second after A)
-- Clip V3.5, SQL Server side, database MV3PgTx, session A: the invoicing of session 41
-- takes an application lock on a name, owned by its transaction, and works five seconds.
SET NOCOUNT ON;
USE MV3PgTx;
BEGIN TRAN;
DECLARE @result int;
EXEC @result = sp_getapplock @Resource = N'invoicing-session-41', @LockMode = 'Exclusive';
SELECT @result AS getapplock_result;
SELECT resource_type, RTRIM(resource_description) AS resource_description, request_mode, request_owner_type
FROM sys.dm_tran_locks
WHERE request_session_id = @@SPID AND resource_type = 'APPLICATION';
WAITFOR DELAY '00:00:05';
COMMIT;
GO
