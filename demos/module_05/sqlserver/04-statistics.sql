-- Clip 5.4, SQL Server side. sql2022, database PachaDataFormation, sqlcmd. Reads only.
-- The statistics of Stage.Session: one object per index, and one per column that a
-- query has filtered on (_WA_Sys_..., auto-created). Then the histogram of the index
-- on DateDebut, at most 200 steps.
SET NOCOUNT ON;
SELECT s.name, s.auto_created, COL_NAME(sc.object_id, sc.column_id) AS first_column
FROM sys.stats AS s
JOIN sys.stats_columns AS sc
  ON sc.object_id = s.object_id AND sc.stats_id = s.stats_id AND sc.stats_column_id = 1
WHERE s.object_id = OBJECT_ID('Stage.Session')
ORDER BY s.auto_created, s.name;

SELECT p.rows, p.rows_sampled, p.steps, p.last_updated
FROM sys.stats AS s
CROSS APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) AS p
WHERE s.object_id = OBJECT_ID('Stage.Session') AND s.name = 'uq_SessionStage_CodeDateLieu';

SELECT TOP (3) h.step_number, h.range_high_key, h.equal_rows, h.range_rows
FROM sys.stats AS s
CROSS APPLY sys.dm_db_stats_histogram(s.object_id, s.stats_id) AS h
WHERE s.object_id = OBJECT_ID('Stage.Session') AND s.name = 'uq_SessionStage_CodeDateLieu'
ORDER BY h.step_number;
