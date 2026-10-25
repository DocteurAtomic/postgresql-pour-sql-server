-- Clip D4.1, SQL Server side: automatic statistics updates, the nearest thing to the
-- ANALYZE half of the autovacuum. SQL Server 2022, base PachaDataFormation, sqlcmd. Read only.
set nocount on;
select name, is_auto_create_stats_on, is_auto_update_stats_on, is_auto_update_stats_async_on,
       compatibility_level
from sys.databases where name = db_name();

-- Rows, modifications since the last update, and the threshold of compatibility level 130
-- and later: the smaller of 500 + 20 % of the rows and the square root of 1,000 times the rows.
select object_schema_name(s.object_id) + '.' + object_name(s.object_id) as table_name,
       s.name as stats_name, p.rows, p.modification_counter, p.last_updated,
       cast(case when 500 + 0.20 * p.rows < sqrt(1000.0 * p.rows)
                 then 500 + 0.20 * p.rows else sqrt(1000.0 * p.rows) end as int) as update_at
from sys.stats as s
cross apply sys.dm_db_stats_properties(s.object_id, s.stats_id) as p
where s.object_id = object_id('Inscription.Inscription')
  and s.stats_id = 1;
