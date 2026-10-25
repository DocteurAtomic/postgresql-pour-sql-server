-- Clip D8.1: inventory of the source database before a migration to PostgreSQL.
-- SQL Server 2022 (sql2022), sqlcmd, database PachaDataFormation, read only.
SET NOCOUNT ON;

-- 1. Volume: tables, rows and reserved space per schema.
SELECT s.name AS schema_name,
       COUNT(DISTINCT t.object_id) AS tables,
       SUM(CASE WHEN p.index_id IN (0, 1) THEN p.row_count ELSE 0 END) AS rows,
       SUM(p.reserved_page_count) * 8 / 1024 AS reserved_mb
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.dm_db_partition_stats AS p ON p.object_id = t.object_id
GROUP BY s.name
ORDER BY reserved_mb DESC;

-- 2. Data types in use, the first thing a type mapping has to cover.
SELECT ty.name AS data_type, COUNT(*) AS columns
FROM sys.columns AS c
JOIN sys.tables AS t ON t.object_id = c.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
GROUP BY ty.name
ORDER BY columns DESC, data_type;

-- 3. T-SQL code to rewrite by hand: modules and their lines.
SELECT o.type_desc, COUNT(*) AS modules,
       SUM(LEN(m.definition) - LEN(REPLACE(m.definition, CHAR(10), '')) + 1) AS lines
FROM sys.sql_modules AS m
JOIN sys.objects AS o ON o.object_id = m.object_id
WHERE o.is_ms_shipped = 0
GROUP BY o.type_desc
ORDER BY lines DESC;

-- 4. Features with no direct equivalent in PostgreSQL, counted in this database and instance.
SELECT feature, objects FROM (VALUES
  ('columnstore indexes', (SELECT COUNT(*) FROM sys.indexes WHERE type IN (5, 6))),
  ('memory-optimized tables', (SELECT COUNT(*) FROM sys.tables WHERE is_memory_optimized = 1)),
  ('CLR assemblies', (SELECT COUNT(*) FROM sys.assemblies WHERE is_user_defined = 1)),
  ('Service Broker queues', (SELECT COUNT(*) FROM sys.service_queues WHERE is_ms_shipped = 0)),
  ('linked servers', (SELECT COUNT(*) FROM sys.servers WHERE is_linked = 1)),
  ('SQL Server Agent jobs', (SELECT COUNT(*) FROM msdb.dbo.sysjobs)),
  ('spatial columns', (SELECT COUNT(*) FROM sys.columns AS c JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
                       JOIN sys.tables AS t ON t.object_id = c.object_id WHERE ty.name IN ('geometry', 'geography'))),
  ('xml columns', (SELECT COUNT(*) FROM sys.columns AS c JOIN sys.tables AS t ON t.object_id = c.object_id
                   WHERE TYPE_NAME(c.user_type_id) = 'xml')),
  ('computed columns', (SELECT COUNT(*) FROM sys.computed_columns AS c JOIN sys.tables AS t ON t.object_id = c.object_id)),
  ('partition functions', (SELECT COUNT(*) FROM sys.partition_functions)),
  ('synonyms', (SELECT COUNT(*) FROM sys.synonyms)),
  ('cross-database references', (SELECT COUNT(*) FROM sys.sql_expression_dependencies
                                 WHERE referenced_database_name IS NOT NULL))
) AS f(feature, objects)
ORDER BY objects DESC, feature;

-- 5. Where they are: the objects behind the non-zero counts.
SELECT 'columnstore' AS feature, OBJECT_SCHEMA_NAME(i.object_id) + '.' + OBJECT_NAME(i.object_id) + ' (' + i.name + ')' AS object_name
FROM sys.indexes AS i WHERE i.type IN (5, 6)
UNION ALL
SELECT 'partitioned', OBJECT_SCHEMA_NAME(i.object_id) + '.' + OBJECT_NAME(i.object_id)
FROM sys.indexes AS i JOIN sys.partition_schemes AS ps ON ps.data_space_id = i.data_space_id WHERE i.index_id IN (0, 1)
UNION ALL
SELECT 'computed', OBJECT_SCHEMA_NAME(c.object_id) + '.' + OBJECT_NAME(c.object_id) + '.' + c.name
FROM sys.computed_columns AS c JOIN sys.tables AS t ON t.object_id = c.object_id
UNION ALL
SELECT 'spatial or xml', OBJECT_SCHEMA_NAME(c.object_id) + '.' + OBJECT_NAME(c.object_id) + '.' + c.name + ' ' + TYPE_NAME(c.user_type_id)
FROM sys.columns AS c JOIN sys.tables AS t ON t.object_id = c.object_id
WHERE TYPE_NAME(c.user_type_id) IN ('geometry', 'geography', 'xml')
UNION ALL
SELECT 'Agent job', name COLLATE DATABASE_DEFAULT FROM msdb.dbo.sysjobs
ORDER BY feature, object_name;
