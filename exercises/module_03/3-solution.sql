-- Module 3 exercise, solution of question 2. Lab database, psql, after 1-start.sql.
-- Drops outils.m03_exercise and the pgstattuple extension at the end.

-- 2a. The table before the UPDATE.
select pg_size_pretty(pg_relation_size('outils.m03_exercise')) as table_size,
       tuple_count, dead_tuple_count, round(free_percent) as free_pct
from pgstattuple('outils.m03_exercise');

-- 2b. One enrollment in three: as many dead tuples, and the table grows.
update outils.m03_exercise set present = not present where inscriptionid % 3 = 0;
select pg_size_pretty(pg_relation_size('outils.m03_exercise')) as table_size,
       tuple_count, dead_tuple_count, round(free_percent) as free_pct
from pgstattuple('outils.m03_exercise');

-- 2c. The estimate of the statistics views, which autovacuum reads.
select pg_stat_force_next_flush();
select n_tup_upd, n_tup_hot_upd, n_dead_tup
from pg_stat_user_tables
where relid = 'outils.m03_exercise'::regclass;

-- 2d. After VACUUM: no dead tuple left, free space inside the file, same size.
vacuum outils.m03_exercise;
select pg_size_pretty(pg_relation_size('outils.m03_exercise')) as table_size,
       tuple_count, dead_tuple_count, round(free_percent) as free_pct
from pgstattuple('outils.m03_exercise');

drop table outils.m03_exercise;
drop extension pgstattuple;
