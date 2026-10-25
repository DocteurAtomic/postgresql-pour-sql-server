-- Clip 4.7, SQL Server side: implicit conversions, truncation, TRY_CAST, CONVERT styles.
-- Read only, in PachaDataFormation (recorded on SQL Server 2022, sqlcmd).
-- The batch with FactureCd = 123 fails on purpose, row by row, at run time.
SET NOCOUNT ON;
SELECT COUNT(*) AS sessions FROM Stage.Session WHERE SessionId = '45';
SELECT LEN(12345) AS len_of_int;
SELECT CAST(3.7 AS int) AS three_point_seven, CAST(2.5 AS int) AS two_point_five,
       CAST(-3.5 AS int) AS minus_three_point_five;
SELECT TRY_CAST('42abc' AS int) AS try_cast;
SELECT CONVERT(varchar(10), CAST('2026-10-20' AS date), 103) AS style_103,
       CONVERT(date, '20/10/2026', 103) AS parsed_103;
GO
SELECT COUNT(*) AS facture FROM Inscription.Facture WHERE FactureCd = 123;
GO
