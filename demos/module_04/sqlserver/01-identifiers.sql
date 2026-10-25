-- Clip 4.1, SQL Server side: names keep their case, and compare with the database collation.
-- Read only, in PachaDataFormation (recorded on SQL Server 2022, sqlcmd).
SET NOCOUNT ON;
SELECT TOP (3) name AS column_name
FROM sys.columns
WHERE object_id = OBJECT_ID(N'Stage.Session')
ORDER BY column_id;

-- The same column, written three ways: a case-insensitive collation finds it each time.
SELECT TOP (1) SessionId AS as_declared, sessionid AS lower_case, SESSIONID AS upper_case
FROM stage.SESSION
ORDER BY as_declared;

-- sysname, the type of a name: nvarchar(128), 256 bytes.
SELECT name, max_length FROM sys.types WHERE name = N'sysname';
