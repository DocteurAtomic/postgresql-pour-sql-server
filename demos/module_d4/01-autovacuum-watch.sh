#!/usr/bin/env bash
# ci: skip (throwaway container, runs on the host)
# Clip D4.1: the autovacuum at work, in a throwaway container pgd4-autovacuum
# (DOCKER=podman for Podman), removed at the end. The launcher wakes up every 5 seconds
# instead of 60 (autovacuum_naptime, an instance setting), so that the demo does not wait;
# nothing else differs from the lab. The lab is not touched.
set -euo pipefail
docker=${DOCKER:-docker}
name=pgd4-autovacuum
image=docker.io/pgvector/pgvector:pg18
cleanup() { $docker rm -f $name >/dev/null 2>&1; }
trap cleanup EXIT
sql() { $docker exec -i $name sh -c 'psql -U postgres -X -v ON_ERROR_STOP=1 2>&1'; }

$docker run -d --name $name -e POSTGRES_PASSWORD=course $image \
    -c autovacuum_naptime=5s >/dev/null
until $docker exec $name pg_isready -U postgres -h 127.0.0.1 -q 2>/dev/null; do sleep 1; done
sleep 2

echo "== three tables of 100,000 rows: global settings, 1 % threshold, autovacuum off"
sql <<'SQL'
create table md4_default as select g as id, md5(g::text) as payload from generate_series(1, 100000) as g;
create table md4_tuned   as select g as id, md5(g::text) as payload from generate_series(1, 100000) as g;
create table md4_off     as select g as id, md5(g::text) as payload from generate_series(1, 100000) as g;
alter table md4_tuned set (autovacuum_vacuum_scale_factor = 0.01, autovacuum_vacuum_threshold = 1000,
                           log_autovacuum_min_duration = 0);
alter table md4_off set (autovacuum_enabled = off);
SQL
sleep 12
echo "== after the first rounds of the launcher: who was analyzed"
sql <<'SQL'
select relname, n_live_tup, n_mod_since_analyze, last_autoanalyze is not null as auto_analyzed,
       last_autovacuum is not null as auto_vacuumed
from pg_stat_user_tables order by relname;
explain select * from md4_off where id <= 100;
explain select * from md4_default where id <= 100;
SQL

echo "== 5,000 rows updated in each table (5 %)"
sql <<'SQL'
update md4_default set payload = upper(payload) where id <= 5000;
update md4_tuned   set payload = upper(payload) where id <= 5000;
update md4_off     set payload = upper(payload) where id <= 5000;
select pg_stat_force_next_flush();
select relname, n_dead_tup from pg_stat_user_tables order by relname;
SQL
sleep 12
echo "== twelve seconds later"
sql <<'SQL'
select relname, n_dead_tup, autovacuum_count, autoanalyze_count,
       total_autovacuum_time > 0 as timed
from pg_stat_user_tables order by relname;
SQL
echo "== the server log of the last autovacuum of md4_tuned"
$docker logs $name 2>&1 | grep -A10 'automatic vacuum of table "postgres.public.md4_tuned"' | tail -11
