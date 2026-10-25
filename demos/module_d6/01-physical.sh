#!/usr/bin/env bash
# Clip D6.1: physical replication seen from the standby. Runs on the host (DOCKER=podman for
# Podman): pgd6-primary restores pachadataformation, pgd6-standby is a clone of it that
# replays its WAL (built as in clip D6.2). The standby gives up a query after 5 seconds of
# conflict instead of the default 30, to keep the demo short. Containers, volumes and the
# network pgd6-net are removed at the end. The lab is not touched.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
p=pgd6-primary
s=pgd6-standby
trap 'cleanup $p $s' EXIT
start_primary $p
restore_db $p
sql $p -d pachadataformation -q -c "create table outils.md6_facture as select * from inscription.facture"
make_standby $p $s standby1 -c max_standby_streaming_delay=5s
wait_replayed $p $s

echo "== 1. one primary, one standby"
for c in $p $s; do
    sql $c -At -F ' | ' -c "select current_setting('cluster_name'), pg_is_in_recovery()"
done
sql $p -c "select application_name, state, sync_state from pg_stat_replication"

echo "== 2. the standby reads, and refuses to write"
sql $s -d pachadataformation -c "select count(*) as sessions, avg(prix)::numeric(8,2) as avg_price from stage.session"
sql $s -d pachadataformation -c "update stage.session set prix = prix + 10 where sessionid = 40" 2>&1 || true
sql $s -d pachadataformation -c "create temp table md6_tmp (id int)" 2>&1 || true

echo "== 3. the whole instance follows: a new database, a change in an existing one"
sql $p -q -c "create database md6_new"
sql $p -d pachadataformation -c "update stage.session set prix = prix + 10 where sessionid = 40"
wait_replayed $p $s
sql $s -c "select datname from pg_database order by oid"
sql $s -d pachadataformation -c "select sessionid, prix from stage.session where sessionid = 40"

# conflict <label>: a repeatable read transaction on the standby counts the table, sleeps
# 10 s and counts again, while the primary deletes rows and vacuums them away.
conflict() {
    echo "-- standby: count, sleep 10 s, count again ($1)"
    sql $s -d pachadataformation -c "\timing on" -c "begin isolation level repeatable read" \
        -c "select count(*) from outils.md6_facture" -c "select pg_sleep(10)" \
        -c "select count(*) from outils.md6_facture" -c "commit" 2>&1 \
        | grep -v -E '^(BEGIN|COMMIT|ROLLBACK|Timing is on)' &
    sleep 3
    echo "-- primary, 3 s later: delete, vacuum"
    sql $p -d pachadataformation -c "delete from outils.md6_facture where relance = $2" \
        -c "vacuum (verbose) outils.md6_facture" 2>&1 | grep -E '^DELETE|tuples:' | sed -E 's/, [0-9]+ remain//'
    sql $p -c "select slot_name, xmin from pg_replication_slots"
    wait
}

echo "== 4. a long query on the standby, a VACUUM on the primary"
conflict "hot_standby_feedback = off" 0
logs $s | grep -A1 'conflict with recovery' | head -2

echo "== 5. the same with hot_standby_feedback = on"
sql $s -At -c "alter system set hot_standby_feedback = on" -c "select pg_reload_conf()" >/dev/null
sleep 1
conflict "hot_standby_feedback = on" 1
sleep 11
echo "-- primary, after the standby's transaction: vacuum again"
sql $p -d pachadataformation -c "vacuum (verbose) outils.md6_facture" 2>&1 | grep -E 'tuples:' | sed -E 's/, [0-9]+ remain//'
