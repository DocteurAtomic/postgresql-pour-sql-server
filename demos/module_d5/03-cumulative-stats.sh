#!/usr/bin/env bash
# Clip D5.3: what the cumulative statistics count, and when they survive: kept after a clean
# shutdown, reset after an immediate one, and the time counters of pg_stat_io. Runs on the
# host (DOCKER=podman for Podman), in a throwaway container, pgd5-stats, with its own copy
# of pachadataformation; removed at the end. Nothing is reset or restarted on the lab.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
c=pgd5-stats
trap '$docker rm -f $c >/dev/null 2>&1 || true' EXIT
start_pg $c
restore_db $c
db() { sql $c -d pachadataformation -q "$@"; }
log_since() { $docker logs --since "$1" $c 2>&1 | sed -E 's/^[0-9-]+ [0-9:.]+ UTC \[[0-9]+\] //'; }

echo "== 1. a database that has just been restored"
db < "$here/03-read-counters.sql"

echo "== 2. a workload, and a deadlock between two sessions"
db < "$here/03-workload.sql"
t=$(date -u +%FT%TZ)
db < "$here/03-deadlock-a.sql" > /dev/null 2>&1 &
sleep 0.3
db < "$here/03-deadlock-b.sql" > /dev/null 2>&1 || true
wait
sleep 1
log_since $t | grep -E '^(ERROR|DETAIL|\s+Process)' | cut -c1-110
db < "$here/03-read-counters.sql"

echo "== 3. clean shutdown (pg_ctl stop -m fast), restart"
stop_pg $c fast
t=$(date -u +%FT%TZ)
start_again $c
log_since $t | grep -E 'shut down at|ready to accept' || true
db < "$here/03-read-counters.sql"

echo "== 4. immediate shutdown (pg_ctl stop -m immediate), restart"
stop_pg $c immediate
t=$(date -u +%FT%TZ)
start_again $c
log_since $t | grep -E 'interrupted|not properly shut down|redo (starts|done)|ready to accept' || true
db < "$here/03-read-counters.sql"

echo "== 5. pg_stat_io, track_io_timing off then on"
db -c "select sum(montantht) from inscription.facture" > /dev/null
db < "$here/03-io.sql"
db -c "alter system set track_io_timing = on" -c "select pg_reload_conf()" > /dev/null
stop_pg $c fast
start_again $c
db -c "show track_io_timing" -c "select sum(montantht) from inscription.facture" > /dev/null
db < "$here/03-io.sql"

echo "== 6. reset by hand: one database, one shared view"
db -c "select pg_stat_reset()" -c "select pg_stat_reset_shared('io')" > /dev/null
db -c "select xact_commit, seq_scan_facture, stats_reset::time(0)
       from pg_stat_database,
            lateral (select seq_scan as seq_scan_facture from pg_stat_user_tables
                     where relid = 'inscription.facture'::regclass) t
       where datname = current_database()"
db -c "select count(*) as io_rows, min(stats_reset)::time(0) as io_reset from pg_stat_io"
