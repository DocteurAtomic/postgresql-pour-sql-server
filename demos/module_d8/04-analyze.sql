-- ci: skip
-- Clip D8.4: what the planner knows right after the load, in the throwaway container of
-- 04-load.sh (autovacuum off, so that the measure does not depend on when it runs).
select count(*) as tables, count(last_analyze) as analyzed, count(last_autoanalyze) as autoanalyzed
from pg_stat_user_tables;
select count(*) as pg_stats_rows from pg_stats where schemaname = 'stage' and tablename = 'session';
explain select sessionid from stage.session where statut = 'ANNULEE';
