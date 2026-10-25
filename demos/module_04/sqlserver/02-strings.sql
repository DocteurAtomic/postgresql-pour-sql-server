-- Clip 4.2, SQL Server side: char(10) keeps its spaces in a concatenation; + and NULL.
-- Read only, in PachaDataFormation (recorded on SQL Server 2022, sqlcmd).
-- Its data are not those of the port: Statut has other values here.
SET NOCOUNT ON;
SELECT TOP (1) Statut, Statut + '|' AS with_plus, CONCAT(Statut, '|') AS with_concat,
       LEN(Statut) AS len, DATALENGTH(Statut) AS bytes
FROM Stage.Session
WHERE Statut IS NOT NULL
ORDER BY SessionId;

SELECT 'Stage ' + NULL AS with_plus, CONCAT('Stage ', NULL) AS with_concat;
