-- ci: skip (T-SQL, scene played by scene.sh with 02a, 02b and 02d)
-- Clip D5.2, SQL Server side, session C (host md5-report): a count in read committed,
-- without READ_COMMITTED_SNAPSHOT (the default of a new database), waits for the locks.
SET NOCOUNT ON;
DECLARE @t0 datetime2 = SYSDATETIME(), @n int;
SELECT @n = COUNT(*) FROM dbo.Session;
SELECT @n AS sessions, DATEDIFF(ms, @t0, SYSDATETIME()) AS waited_ms;
GO
