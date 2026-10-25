-- ci: skip (pg_stat_reset resets the counters of the whole database: run it on a copy)
-- Clip D4.4: what pg_stat_reset() also erases. Play it on a copy of the lab database,
-- never on the database whose indexes you measure:
--   docker compose exec db createdb -U postgres -T pachadataformation pdf_md4
--   docker compose exec -T db psql -U postgres -d pdf_md4 < demos/module_d4/04-stat-reset.sql
drop table if exists outils.md4_reset;
create table outils.md4_reset as
select g as id, md5(g::text) as payload from generate_series(1, 100000) as g;
vacuum analyze outils.md4_reset;
update outils.md4_reset set payload = upper(payload) where id <= 15000;
select pg_stat_force_next_flush();

-- The counters autovacuum reads: 15,000 dead tuples, against a threshold of 20,050.
select n_dead_tup, last_vacuum is not null as vacuumed, last_analyze is not null as analyzed
from pg_stat_user_tables where relid = 'outils.md4_reset'::regclass;

select pg_stat_reset();

-- The same table: no dead tuple left to count, while the table still holds them.
select n_dead_tup, last_vacuum is not null as vacuumed, last_analyze is not null as analyzed
from pg_stat_user_tables where relid = 'outils.md4_reset'::regclass;
select dead_tuple_count from pgstattuple('outils.md4_reset');
select stats_reset is not null as reset_recorded from pg_stat_database
where datname = current_database();

drop table outils.md4_reset;
