-- ci: skip (T-SQL, plays on SQL Server)
-- Clip V1.3, SQL Server side: conditional aggregates, STRING_AGG, PERCENTILE_CONT, ROLLUP
-- and the RANGE frame. Read only, in PachaDataFormation (recorded on SQL Server 2022,
-- sqlcmd). Its data are not those of the port: compare the behaviors, not the numbers.
-- Two batches fail on purpose.
SET NOCOUNT ON;
-- Conditional aggregates, the T-SQL way.
SELECT YEAR(DateDebut) AS year, COUNT(*) AS sessions,
       SUM(CASE WHEN IntraEntrerprise = 1 THEN 1 ELSE 0 END) AS intra,
       SUM(CASE WHEN IntraEntrerprise = 0 THEN 1 ELSE 0 END) AS inter
FROM Stage.Session
WHERE DateDebut >= '2018-01-01' AND DateDebut < '2021-01-01'
GROUP BY YEAR(DateDebut)
ORDER BY year;

-- STRING_AGG with WITHIN GROUP after the parentheses.
SELECT TOP (3) l.Nom AS venue, STRING_AGG(sf.Nom, ', ') WITHIN GROUP (ORDER BY sf.Nom) AS rooms
FROM Reference.LieuFormation l
JOIN Reference.SalleFormation sf ON sf.LieuFormationId = l.LieuFormationId
GROUP BY l.Nom
ORDER BY l.Nom;
GO
-- PERCENTILE_CONT without OVER is refused.
SELECT YEAR(DateDebut) AS year,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Prix) AS median_price
FROM Stage.Session
GROUP BY YEAR(DateDebut);
GO
-- The usual workaround: OVER (PARTITION BY) and DISTINCT.
SELECT DISTINCT YEAR(DateDebut) AS year,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Prix)
           OVER (PARTITION BY YEAR(DateDebut)) AS median_price
FROM Stage.Session
WHERE DateDebut >= '2018-01-01' AND DateDebut < '2021-01-01'
ORDER BY year;

-- The old WITH ROLLUP syntax, still accepted.
SELECT IntraEntrerprise, COUNT(*) AS sessions
FROM Stage.Session
GROUP BY IntraEntrerprise WITH ROLLUP;
GO
-- A RANGE frame with an offset is refused.
SELECT SessionId, DateDebut,
       COUNT(*) OVER (ORDER BY DateDebut RANGE BETWEEN 365 PRECEDING AND CURRENT ROW) AS previous_year
FROM Stage.Session
WHERE StageId = 119;
GO
