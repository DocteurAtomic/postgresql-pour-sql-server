-- ci: skip (T-SQL, plays on SQL Server)
-- Clip V4.3, SQL Server side, in MV4PgIndex (00-setup.sql). Under French_CI_AS, the plain
-- index on Email serves LIKE 'abc%' with a seek; LIKE '%abc%' reads the whole index.
SET NOCOUNT ON;
GO
SET SHOWPLAN_TEXT ON;
GO
SELECT ContactId, Email FROM dbo.Contact WHERE Email LIKE 'l.leb%';
GO
SELECT ContactId, Email FROM dbo.Contact WHERE Email LIKE '%lebas%';
GO
SET SHOWPLAN_TEXT OFF;
GO
SET STATISTICS IO ON;
SELECT COUNT(*) AS prefix_rows FROM dbo.Contact WHERE Email LIKE 'l.leb%';
SELECT COUNT(*) AS substring_rows FROM dbo.Contact WHERE Email LIKE '%lebas%';
SET STATISTICS IO OFF;
GO
