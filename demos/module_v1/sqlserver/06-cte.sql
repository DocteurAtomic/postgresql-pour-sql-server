-- ci: skip (T-SQL, plays on SQL Server)
-- Clip V1.6, SQL Server side: a recursive CTE, MAXRECURSION, and OUTPUT INTO.
-- Recorded on SQL Server 2022 (sqlcmd), after 00-setup.sql; reads PachaDataFormation and
-- writes only in MV1PgDml. The second batch fails on purpose.
USE MV1PgDml;
SET NOCOUNT ON;
-- No RECURSIVE keyword: the CTE refers to itself.
WITH years AS (
    SELECT 2011 AS year
    UNION ALL
    SELECT year + 1 FROM years WHERE year < 2016
)
SELECT y.year, COUNT(s.SessionId) AS sessions
FROM years y
LEFT JOIN PachaDataFormation.Stage.Session s ON YEAR(s.DateDebut) = y.year
GROUP BY y.year
ORDER BY y.year;
GO
-- The days of 2020: 366 levels, more than the default limit of 100.
WITH days AS (
    SELECT CAST('2020-01-01' AS date) AS day
    UNION ALL
    SELECT DATEADD(day, 1, day) FROM days WHERE day < '2020-12-31'
)
SELECT COUNT(*) AS days FROM days;
GO
WITH days AS (
    SELECT CAST('2020-01-01' AS date) AS day
    UNION ALL
    SELECT DATEADD(day, 1, day) FROM days WHERE day < '2020-12-31'
)
SELECT COUNT(*) AS days FROM days
OPTION (MAXRECURSION 0);
GO
-- OUTPUT ... INTO moves the deleted rows to an archive in one statement.
DROP TABLE IF EXISTS dbo.SessionArchive;
CREATE TABLE dbo.SessionArchive (SessionId int, StageId int, DateDebut date, Prix decimal(8, 2));
DELETE FROM dbo.Session
OUTPUT deleted.SessionId, deleted.StageId, deleted.DateDebut, deleted.Prix
INTO dbo.SessionArchive (SessionId, StageId, DateDebut, Prix)
WHERE DateDebut < '2012-01-01';
SELECT (SELECT COUNT(*) FROM dbo.Session) AS remaining,
       (SELECT COUNT(*) FROM dbo.SessionArchive) AS archived;
DROP TABLE dbo.SessionArchive;
GO
