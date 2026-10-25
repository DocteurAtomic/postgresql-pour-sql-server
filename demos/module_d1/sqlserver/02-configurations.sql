-- Clip D1.2, SQL Server side: sp_configure and sys.configurations.
-- Read only, on any SQL Server instance (recorded on SQL Server 2022, sqlcmd).
SET NOCOUNT ON;
-- value: what was configured; value_in_use: what runs. is_dynamic = 0: restart needed.
SELECT name, value, value_in_use, is_dynamic, is_advanced
FROM sys.configurations
WHERE name IN (N'max server memory (MB)', N'cost threshold for parallelism',
               N'max degree of parallelism', N'user connections', N'fill factor (%)')
ORDER BY name;

SELECT is_dynamic, COUNT(*) AS options
FROM sys.configurations
GROUP BY is_dynamic;

