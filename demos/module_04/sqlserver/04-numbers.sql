-- Clip 4.4, SQL Server side: AVG of an integer column, bit compared with 1, a float INSEE code.
-- Read only, in PachaDataFormation (recorded on SQL Server 2022, sqlcmd).
-- Its data are not those of the port: compare the types, not the numbers.
SET NOCOUNT ON;
SELECT 7 / 2 AS integer_division;
SELECT AVG(Duree) AS avg_int, AVG(Duree * 1.0) AS avg_decimal FROM Stage.Stage;
SELECT COUNT(*) AS with_one FROM Inscription.Inscription WHERE Present = 1;
SELECT COUNT(*) AS with_true FROM Inscription.Inscription WHERE Present = 'true';
SELECT TOP (3) NomVille, CodePostal, CodeINSEE FROM Reference.ville ORDER BY VilleId;
