-- ci: skip (T-SQL, plays on SQL Server)
-- Clip V1.2, SQL Server side: CROSS APPLY, OUTER APPLY and GENERATE_SERIES.
-- Read only, in PachaDataFormation (recorded on SQL Server 2022, sqlcmd).
-- Its data are not those of the port: compare the behaviors, not the rows.
SET NOCOUNT ON;
-- CROSS APPLY: the two latest sessions from December 2017, per course (the sessions of
-- these courses end in 2017 here, in 2020 in the port).
SELECT sl.Titre, last2.SessionId, last2.DateDebut
FROM Stage.StageLangue sl
CROSS APPLY (SELECT TOP (2) s.SessionId, s.DateDebut
             FROM Stage.Session s
             WHERE s.StageId = sl.StageId AND s.LangueCd = sl.LangueCd
               AND s.DateDebut >= '2017-12-01'
             ORDER BY s.DateDebut DESC) AS last2
WHERE sl.Titre LIKE 'PostgreSQL 9 %'
ORDER BY sl.Titre, last2.DateDebut DESC;

-- OUTER APPLY keeps the courses without a session.
SELECT sl.Titre, last2.SessionId, last2.DateDebut
FROM Stage.StageLangue sl
OUTER APPLY (SELECT TOP (2) s.SessionId, s.DateDebut
             FROM Stage.Session s
             WHERE s.StageId = sl.StageId AND s.LangueCd = sl.LangueCd
               AND s.DateDebut >= '2017-12-01'
             ORDER BY s.DateDebut DESC) AS last2
WHERE sl.Titre LIKE 'PostgreSQL 9 %'
ORDER BY sl.Titre, last2.DateDebut DESC;
GO
-- GENERATE_SERIES (2022) takes numbers only: a series of dates is refused.
SELECT value FROM GENERATE_SERIES(CAST('2026-11-02' AS date), CAST('2026-11-06' AS date));
GO
-- The days of a session: numbers, then DATEADD.
SELECT TOP (1) WITH TIES s.SessionId, DATEADD(day, g.value, s.DateDebut) AS day
FROM Stage.Session s
JOIN Stage.Stage st ON st.StageId = s.StageId
CROSS APPLY GENERATE_SERIES(0, CAST(st.Duree AS int) - 1) AS g
WHERE s.StageId = 113
ORDER BY s.SessionId;
GO
