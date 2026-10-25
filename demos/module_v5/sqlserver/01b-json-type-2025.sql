-- ci: skip (T-SQL, plays on SQL Server 2025)
-- Clip V5.1, SQL Server 2025 side: the native json type and its duplicate keys. Recorded on
-- the sql2025 lab container, in a database of its own, MV5PgJson, dropped at the end.
SET NOCOUNT ON;
IF DB_ID(N'MV5PgJson') IS NOT NULL DROP DATABASE MV5PgJson;
CREATE DATABASE MV5PgJson;
GO
USE MV5PgJson;
SET NOCOUNT ON;
CREATE TABLE dbo.Evaluation (EvaluationId int PRIMARY KEY, Doc json NOT NULL);
INSERT INTO dbo.Evaluation VALUES (1, N'{"b": 1, "a": 2, "a": 3}');
-- The json type keeps the first value of a duplicate key, and drops the white space.
SELECT CAST(Doc AS nvarchar(max)) AS doc, JSON_VALUE(Doc, '$.a') AS a_value
FROM dbo.Evaluation;
-- A scalar is not a valid json value.
BEGIN TRY
    INSERT INTO dbo.Evaluation VALUES (2, N'42');
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS error_number, ERROR_MESSAGE() AS error_message;
END CATCH;
-- The aggregates of SQL Server 2025.
SELECT JSON_ARRAYAGG(v.n ORDER BY v.n) AS arrayagg
FROM (VALUES (3), (1), (2)) AS v (n);
GO
USE master;
DROP DATABASE MV5PgJson;
SELECT @@VERSION AS version;
GO
