-- ci: skip (T-SQL, the queries to rewrite; they run on SQL Server, not in psql)
-- Module V1 exercise, starting point: five T-SQL queries written for PachaDataFormation.
-- Rewrite each one for PostgreSQL, against the pachadataformation database of the lab.
-- The names are those of SQL Server; in the port they are in lower case.

-- 1. The five most expensive sessions of 2020, ties included, with their end date and
--    their note (0 when there is none).
SELECT TOP (5) WITH TIES SessionId, DateDebut, DATEADD(day, 4, DateDebut) AS DateFin,
       ISNULL(Note, 0) AS Note, Prix
FROM Stage.Session
WHERE YEAR(DateDebut) = 2020
ORDER BY Prix DESC;

-- 2. For each venue, its latest session, and the venues without any session.
SELECT l.Nom AS Lieu, last1.SessionId, last1.DateDebut, sf.Nom AS Salle
FROM Reference.LieuFormation l
OUTER APPLY (SELECT TOP (1) s.SessionId, s.DateDebut, s.SalleFormationId
             FROM Stage.Session s
             JOIN Reference.SalleFormation sf2 ON sf2.SalleFormationId = s.SalleFormationId
             WHERE sf2.LieuFormationId = l.LieuFormationId
             ORDER BY s.DateDebut DESC) AS last1
LEFT JOIN Reference.SalleFormation sf ON sf.SalleFormationId = last1.SalleFormationId
ORDER BY l.Nom;

-- 3. For the PostgreSQL 9 courses: sessions in 2019 and in 2020, and the median price.
SELECT DISTINCT sl.Titre,
       SUM(CASE WHEN YEAR(s.DateDebut) = 2019 THEN 1 ELSE 0 END)
           OVER (PARTITION BY sl.Titre) AS Sessions2019,
       SUM(CASE WHEN YEAR(s.DateDebut) = 2020 THEN 1 ELSE 0 END)
           OVER (PARTITION BY sl.Titre) AS Sessions2020,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY s.Prix)
           OVER (PARTITION BY sl.Titre) AS PrixMedian
FROM Stage.StageLangue sl
JOIN Stage.Session s ON s.StageId = sl.StageId AND s.LangueCd = sl.LangueCd
WHERE sl.Titre LIKE 'PostgreSQL 9 %'
ORDER BY sl.Titre;

-- 4. Raise by 5 % the price of the 2012 sessions held at Centre Pacha Genève, and list
--    the old and new prices. On SQL Server, it runs in a transaction that is rolled back:
--    the database is not changed.
BEGIN TRAN;
UPDATE Stage.Session SET Prix = s.Prix * 1.05
OUTPUT inserted.SessionId, deleted.Prix AS AncienPrix, inserted.Prix AS NouveauPrix
FROM Stage.Session s
JOIN Reference.SalleFormation sf ON sf.SalleFormationId = s.SalleFormationId
JOIN Reference.LieuFormation l ON l.LieuFormationId = sf.LieuFormationId
WHERE l.Nom = 'Centre Pacha Genève' AND YEAR(s.DateDebut) = 2012;
ROLLBACK;

-- 5. The sessions per month of 2012, empty months included.
WITH Mois AS (
    SELECT CAST('2012-01-01' AS date) AS Mois
    UNION ALL
    SELECT DATEADD(month, 1, Mois) FROM Mois WHERE Mois < '2012-12-01'
)
SELECT m.Mois, COUNT(s.SessionId) AS Sessions
FROM Mois m
LEFT JOIN Stage.Session s
       ON s.DateDebut >= m.Mois AND s.DateDebut < DATEADD(month, 1, m.Mois)
GROUP BY m.Mois
ORDER BY m.Mois
OPTION (MAXRECURSION 12);
