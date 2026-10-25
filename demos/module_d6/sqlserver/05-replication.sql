-- ci: skip (T-SQL, plays on SQL Server)
-- Clip D6.5, SQL Server side (recorded on SQL Server 2022, sqlcmd, read only). No
-- publication, no distributor; and the tables of PachaDataFormation that a transactional
-- publication would refuse as articles, for want of a primary key.
SET NOCOUNT ON;
SELECT name, is_published, is_subscribed, is_merge_published, is_distributor
FROM sys.databases
WHERE name = N'PachaDataFormation';
SELECT COUNT(*) AS distributors FROM sys.servers WHERE is_distributor = 1;
SELECT s.name AS schema_name, t.name AS table_name
FROM PachaDataFormation.sys.tables t
JOIN PachaDataFormation.sys.schemas s ON s.schema_id = t.schema_id
WHERE NOT EXISTS (SELECT 1 FROM PachaDataFormation.sys.indexes i
                  WHERE i.object_id = t.object_id AND i.is_primary_key = 1)
ORDER BY 1, 2;
