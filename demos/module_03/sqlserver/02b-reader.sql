-- ci: skip (T-SQL, two sessions on SQL Server)
-- Clip 3.2, SQL Server side, session B: reads session 40 in read committed while A holds
-- its UPDATE, and says how long the read waited.
USE M03PgRcsi;
SET NOCOUNT ON;
DECLARE @t0 datetime2 = SYSDATETIME(), @prix decimal(8, 2);
SELECT @prix = Prix FROM dbo.Session WHERE SessionId = 40;
SELECT 40 AS SessionId, @prix AS Prix, DATEDIFF(ms, @t0, SYSDATETIME()) AS waited_ms;
GO
