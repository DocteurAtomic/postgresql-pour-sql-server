-- Clip 2.2, SQL Server side: max server memory, and the buffer pool per object.
-- Read only, in PachaDataFormation (recorded on SQL Server 2022, sqlcmd).
SET NOCOUNT ON;
SELECT name, value_in_use
FROM sys.configurations
WHERE name IN (N'max server memory (MB)', N'min server memory (MB)')
ORDER BY name;

SELECT TOP (5) s.name + N'.' + o.name AS table_name,
       COUNT(*) AS buffers,
       COUNT(*) * 8 / 1024 AS cached_mb
FROM sys.dm_os_buffer_descriptors AS b
JOIN sys.allocation_units AS a ON a.allocation_unit_id = b.allocation_unit_id
JOIN sys.partitions AS p ON p.hobt_id = a.container_id
JOIN sys.objects AS o ON o.object_id = p.object_id
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE b.database_id = DB_ID() AND o.is_ms_shipped = 0
GROUP BY s.name, o.name
ORDER BY buffers DESC;
