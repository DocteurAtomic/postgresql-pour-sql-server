-- ci: skip (T-SQL, plays on SQL Server)
-- Clip V5.4, SQL Server 2022 side: a list of identifiers passed as a string.
-- Read only (sqlcmd, database PachaDataFormation).
SET NOCOUNT ON;
DECLARE @ids varchar(100) = '887,40,90';
-- STRING_SPLIT returns strings; the third argument (2022) adds the position.
SELECT value, ordinal FROM STRING_SPLIT(@ids, ',', 1);
SELECT s.SessionId, s.DateDebut
FROM Stage.Session AS s
WHERE s.SessionId IN (SELECT CAST(value AS int) FROM STRING_SPLIT(@ids, ','))
ORDER BY s.SessionId;
GO
-- An empty IN list is a syntax error here too.
SELECT SessionId FROM Stage.Session WHERE SessionId IN ();
GO
