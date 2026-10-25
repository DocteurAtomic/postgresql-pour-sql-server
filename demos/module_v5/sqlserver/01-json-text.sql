-- ci: skip (T-SQL, plays on SQL Server)
-- Clip V5.1, SQL Server 2022 side: JSON is text in an nvarchar. Read only, no table
-- (sqlcmd, database PachaDataFormation).
SET NOCOUNT ON;
DECLARE @j nvarchar(max) = N'{"b": 1,   "a": 2, "a": 3}';
-- ISJSON accepts the duplicate key, JSON_VALUE reads the first one.
SELECT ISJSON(@j) AS is_json, JSON_VALUE(@j, '$.a') AS a_value;
-- OPENJSON sees both pairs.
SELECT [key], value FROM OPENJSON(@j);
-- Two equal documents, written differently, are two different strings.
SELECT CASE WHEN N'{"a": 1, "b": [1, 2]}' = N'{"b": [1,2], "a": 1}'
            THEN 'equal' ELSE 'different' END AS string_comparison;
-- ISJSON with a type constraint (2022): a scalar is valid JSON only as VALUE or SCALAR.
SELECT ISJSON(N'42') AS bare, ISJSON(N'42', VALUE) AS as_value, ISJSON(N'[1, 2]', OBJECT) AS array_as_object;
GO
