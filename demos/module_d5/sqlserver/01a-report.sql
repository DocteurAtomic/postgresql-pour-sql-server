-- ci: skip (T-SQL, scene played by scene.sh with 01b and 01c)
-- Clip D5.1, SQL Server side, session A (host md5-report): a long report, about ten
-- seconds of a cross join, run in parallel.
SET NOCOUNT ON;
DECLARE @t0 datetime2 = SYSDATETIME();
SELECT COUNT_BIG(*) AS matches
FROM dbo.Inscription a
CROSS JOIN (SELECT TOP (6000) SessionId FROM dbo.Session) b
WHERE a.ContactId + b.SessionId < 0;
SELECT DATEDIFF(ms, @t0, SYSDATETIME()) AS report_ms;
GO
