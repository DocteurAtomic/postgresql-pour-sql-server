#!/usr/bin/env bash
# ci: skip (throwaway container, runs on the host)
# Clip D4.5: pg_cron, a scheduler inside the instance, and the command line tools that a
# cron job or a systemd timer calls. Runs in a throwaway container pgd4-cron (DOCKER=podman
# for Podman), removed at the end: the image of the lab plus the package postgresql-18-cron,
# installed at start from the PGDG repository the image already declares; it needs network
# access. pg_cron is loaded at start (shared_preload_libraries). The lab is not touched.
set -euo pipefail
docker=${DOCKER:-docker}
name=pgd4-cron
image=docker.io/pgvector/pgvector:pg18
cleanup() { $docker rm -f $name >/dev/null 2>&1; }
trap cleanup EXIT
sql() { $docker exec -i $name sh -c 'psql -U postgres -X -v ON_ERROR_STOP=1 2>&1'; }

$docker run -d --name $name -e POSTGRES_PASSWORD=course --entrypoint bash $image -c '
    apt-get update -qq >/dev/null && apt-get install -y -qq postgresql-18-cron >/dev/null
    exec docker-entrypoint.sh postgres -c shared_preload_libraries=pg_cron \
        -c cron.database_name=postgres -c cron.timezone=Europe/Paris' >/dev/null
until $docker exec $name pg_isready -U postgres -h 127.0.0.1 -q 2>/dev/null; do sleep 2; done
sleep 2

echo "== the extension, in the database named by cron.database_name"
sql <<'SQL'
create extension pg_cron;
select extname, extversion from pg_extension where extname = 'pg_cron';
create database appli;
SQL

echo "== three jobs: every night, every Sunday, every ten seconds"
sql <<'SQL'
select cron.schedule_in_database('nightly-analyze', '30 2 * * *', 'vacuum (analyze)', 'appli');
select cron.schedule_in_database('weekly-check', '0 4 * * 0',
    $$select bt_index_check(indexrelid, true) from pg_index
      join pg_class on pg_class.oid = indexrelid
      where relam = (select oid from pg_am where amname = 'btree')$$, 'appli');
select cron.schedule('ten-seconds', '10 seconds', 'select count(*) from pg_stat_activity');
select jobid, jobname, schedule, database, active from cron.job order by jobid;
SQL
sleep 25
echo "== twenty-five seconds later, the history of the runs"
sql <<'SQL'
select j.jobname, d.status, d.return_message, d.end_time - d.start_time as duration
from cron.job_run_details as d join cron.job as j using (jobid)
order by d.start_time limit 3;
select cron.unschedule('ten-seconds');
SQL

echo "== the command of the weekly check, every two seconds, to see it run now"
sql <<'SQL'
select cron.schedule_in_database('check-now', '2 seconds',
    (select command from cron.job where jobname = 'weekly-check'), 'appli');
SQL
sleep 6
sql <<'SQL'
select j.jobname, d.status, split_part(d.return_message, E'\n', 1) as return_message
from cron.job_run_details as d join cron.job as j using (jobid)
where j.jobname = 'check-now' order by d.start_time limit 1;
select cron.unschedule('check-now');
SQL

echo "== what a cron job or a systemd timer calls: vacuumdb and reindexdb"
$docker exec $name vacuumdb -U postgres --all --analyze-only --jobs 2 2>&1
$docker exec $name reindexdb -U postgres --dbname appli --concurrently --verbose 2>&1 | sed -n 1,2p
echo "== pg_amcheck on every database, then with --install-missing"
$docker exec $name pg_amcheck -U postgres --all 2>&1 && echo "exit code 0" || echo "exit code $?"
$docker exec $name pg_amcheck -U postgres --all --install-missing --heapallindexed 2>&1 && echo "exit code 0" || echo "exit code $?"
