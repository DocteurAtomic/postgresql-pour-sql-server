-- ci: skip (T-SQL, plays on SQL Server)
-- Clip V1.1, SQL Server side: the T-SQL constructs that 01-common-queries.sql translates.
-- Read only, in PachaDataFormation (recorded on SQL Server 2022, sqlcmd).
-- Its data are not those of the port: compare the behaviors, not the numbers.
SET NOCOUNT ON;
-- NULL sorts as the smallest value: last in a descending sort.
SELECT TOP (3) SessionId, Note FROM Stage.Session ORDER BY Note DESC, SessionId;

-- WITH TIES needs an ORDER BY here too.
SELECT TOP (4) WITH TIES StageId, COUNT(*) AS sessions
FROM Stage.Session
GROUP BY StageId
ORDER BY sessions DESC;

-- ISNULL takes the type of its first argument and truncates; COALESCE does not.
SELECT ISNULL(CAST(NULL AS varchar(2)), 'abcdef') AS with_isnull,
       COALESCE(CAST(NULL AS varchar(2)), 'abcdef') AS with_coalesce;

-- LEN ignores trailing spaces; DATALENGTH counts bytes.
SELECT LEN('abc  ') AS len, DATALENGTH('abc  ') AS datalength;

-- DATEADD keeps the type of the date; DATEDIFF counts day boundaries.
SELECT DATEADD(day, 30, CAST('2026-10-25' AS date)) AS plus_30_days,
       DATEADD(month, 1, CAST('2026-01-31' AS date)) AS plus_1_month,
       DATEDIFF(day, '2026-01-01', '2026-12-31') AS days_between;
GO
