-- ci: skip (T-SQL, two sessions: play it one second after 05a-applock.sql)
-- Clip V3.5, SQL Server side, database MV3PgTx, session B: a second run of the invoicing,
-- without waiting (@LockTimeout = 0), then waiting until A commits. Then a lock owned by
-- the session, released by sp_releaseapplock.
SET NOCOUNT ON;
USE MV3PgTx;
DECLARE @result int, @start datetime2 = SYSDATETIME();
BEGIN TRAN;
EXEC @result = sp_getapplock @Resource = N'invoicing-session-41', @LockMode = 'Exclusive',
     @LockTimeout = 0;
SELECT @result AS no_wait_result;
EXEC @result = sp_getapplock @Resource = N'invoicing-session-41', @LockMode = 'Exclusive';
SELECT @result AS wait_result, DATEDIFF(millisecond, @start, SYSDATETIME()) AS waited_ms;
COMMIT;
EXEC @result = sp_getapplock @Resource = N'invoicing-session-41', @LockMode = 'Shared',
     @LockOwner = 'Session';
SELECT @result AS session_lock_result,
       APPLOCK_MODE(N'public', N'invoicing-session-41', N'Session') AS session_mode;
EXEC @result = sp_releaseapplock @Resource = N'invoicing-session-41', @LockOwner = 'Session';
SELECT @result AS release_result;
GO
