-- ci: skip (T-SQL, plays on SQL Server 2025)
-- Module V6, SQL Server side, clip V6.4 (recorded on SQL Server 2025 CU7, sqlcmd; SQL Server
-- 2022 has no vector type). Creates the database MV6PgVector, the same 100,000 vectors of
-- 16 dimensions as 00-setup.sql, computed the same way, and drops the database at the end.
-- The vector index and VECTOR_SEARCH are preview features of SQL Server 2025: they need
-- PREVIEW_FEATURES, a database scoped configuration.
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;  -- sqlcmd sets it OFF; CREATE VECTOR INDEX needs it ON
IF DB_ID(N'MV6PgVector') IS NOT NULL
BEGIN
    ALTER DATABASE MV6PgVector SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE MV6PgVector;
END;
CREATE DATABASE MV6PgVector;
GO
USE MV6PgVector;
GO
-- 1. The type and VECTOR_DISTANCE.
DECLARE @v1 AS VECTOR(2) = '[1,1]';
DECLARE @v2 AS VECTOR(2) = '[-1,-1]';
SELECT VECTOR_DISTANCE('euclidean', @v1, @v2) AS euclidean,
       VECTOR_DISTANCE('cosine', @v1, @v2) AS cosine,
       VECTOR_DISTANCE('dot', @v1, @v2) AS negative_dot;
GO
-- 2. The same vectors as the PostgreSQL demo: the fractional part of a sine.
CREATE TABLE dbo.Vecteur (Id int NOT NULL PRIMARY KEY, Categorie int NOT NULL, Embedding VECTOR(16) NOT NULL);
WITH v AS (
    SELECT n.value AS Id, k.value AS k,
           ABS(SIN(n.value * 12.9898 + k.value * 78.233) * 43758.5453)
           - FLOOR(ABS(SIN(n.value * 12.9898 + k.value * 78.233) * 43758.5453)) AS x
    FROM GENERATE_SERIES(1, 100000) AS n
    CROSS JOIN GENERATE_SERIES(1, 16) AS k
)
INSERT INTO dbo.Vecteur (Id, Categorie, Embedding)
SELECT Id, Id % 100,
       CAST('[' + STRING_AGG(CONVERT(varchar(30), x, 3), ',') WITHIN GROUP (ORDER BY k) + ']' AS VECTOR(16))
FROM v
GROUP BY Id;
SELECT COUNT(*) AS vectors FROM dbo.Vecteur;
GO
-- 3. The ten nearest neighbours of the vector 42, exactly: VECTOR_DISTANCE never uses an index.
DECLARE @q VECTOR(16) = (SELECT Embedding FROM dbo.Vecteur WHERE Id = 42);
SELECT TOP (10) Id, VECTOR_DISTANCE('euclidean', @q, Embedding) AS distance
FROM dbo.Vecteur
ORDER BY distance;
GO
-- 4. The vector index, in preview.
CREATE VECTOR INDEX VX_Vecteur_Embedding ON dbo.Vecteur (Embedding) WITH (METRIC = 'euclidean', TYPE = 'DiskANN');
GO
ALTER DATABASE SCOPED CONFIGURATION SET PREVIEW_FEATURES = ON;
GO
DECLARE @start datetime2 = SYSDATETIME();
CREATE VECTOR INDEX VX_Vecteur_Embedding ON dbo.Vecteur (Embedding) WITH (METRIC = 'euclidean', TYPE = 'DiskANN');
SELECT DATEDIFF(second, @start, SYSDATETIME()) AS build_seconds;
GO
SELECT name, type_desc FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.Vecteur');
GO
-- 5. The approximate search, with the syntax of the latest index version, then with TOP_N.
DECLARE @q VECTOR(16) = (SELECT Embedding FROM dbo.Vecteur WHERE Id = 42);
SELECT TOP (10) WITH APPROXIMATE t.Id, r.distance
FROM VECTOR_SEARCH(TABLE = dbo.Vecteur AS t, COLUMN = Embedding, SIMILAR_TO = @q, METRIC = 'euclidean') AS r
ORDER BY r.distance;
GO
DECLARE @q VECTOR(16) = (SELECT Embedding FROM dbo.Vecteur WHERE Id = 42);
SELECT TOP (10) t.Id, r.distance
FROM VECTOR_SEARCH(TABLE = dbo.Vecteur AS t, COLUMN = Embedding, SIMILAR_TO = @q, METRIC = 'euclidean', TOP_N = 10) AS r
ORDER BY r.distance;
GO
-- 6. A filter on 1 % of the rows.
DECLARE @q VECTOR(16) = (SELECT Embedding FROM dbo.Vecteur WHERE Id = 42);
SELECT TOP (10) WITH APPROXIMATE t.Id, r.distance
FROM VECTOR_SEARCH(TABLE = dbo.Vecteur AS t, COLUMN = Embedding, SIMILAR_TO = @q, METRIC = 'euclidean') AS r
WHERE t.Categorie = 7
ORDER BY r.distance;
GO
DECLARE @q VECTOR(16) = (SELECT Embedding FROM dbo.Vecteur WHERE Id = 42);
SELECT TOP (10) t.Id, r.distance
FROM VECTOR_SEARCH(TABLE = dbo.Vecteur AS t, COLUMN = Embedding, SIMILAR_TO = @q, METRIC = 'euclidean', TOP_N = 10) AS r
WHERE t.Categorie = 7
ORDER BY r.distance;
GO
-- 7. A write into the indexed table.
INSERT INTO dbo.Vecteur (Id, Categorie, Embedding)
SELECT 100001, 1, Embedding FROM dbo.Vecteur WHERE Id = 42;
SELECT COUNT(*) AS vectors FROM dbo.Vecteur;
GO
USE master;
ALTER DATABASE MV6PgVector SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE MV6PgVector;
