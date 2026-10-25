-- ci: skip (T-SQL, plays on SQL Server)
-- Clip V2.1, SQL Server side: a variable lives in its batch, and SELECT @v = ... over
-- several rows keeps the last one. Read only, in PachaDataFormation (sqlcmd).
SET NOCOUNT ON;
SELECT COUNT(*) AS sessions, MAX(SessionId) AS last_sessionid
FROM Stage.Session
WHERE StageId = 12;
DECLARE @d date = '1900-01-01';
SELECT @d = DateDebut FROM Stage.Session WHERE StageId = 12 ORDER BY SessionId;
PRINT CONCAT('last row: ', @d);
SELECT @d = DateDebut FROM Stage.Session WHERE StageId = -1;
PRINT CONCAT('no row: ', @d);
GO
-- The next batch does not know @d.
PRINT @d;
GO
