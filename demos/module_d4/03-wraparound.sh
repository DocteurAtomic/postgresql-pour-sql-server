#!/usr/bin/env bash
# ci: skip (throwaway container, runs on the host)
# Clip D4.3: an instance brought close to transaction id wraparound by pg_resetwal, in a
# throwaway container pgd4-wrap (DOCKER=podman for Podman), removed at the end. Never run
# pg_resetwal on an instance whose data you care about: it is used here only to move the
# counter two billion transactions ahead in a second. The lab is not touched.
set -euo pipefail
docker=${DOCKER:-docker}
$docker run --rm --name pgd4-wrap --user postgres --entrypoint bash \
    docker.io/pgvector/pgvector:pg18 -c '
set -e
export PATH=/usr/lib/postgresql/18/bin:$PATH
D=/tmp/wrap
opts="-c listen_addresses= -k /tmp -c autovacuum_naptime=5s -c log_autovacuum_min_duration=0 -c max_prepared_transactions=5"
start() { pg_ctl -D $D -l $D.log -o "$opts" -w start >/dev/null; }
stop() { pg_ctl -D $D -m fast -w stop >/dev/null; }
psql() { command psql -h /tmp -U postgres -X "$@" 2>&1 || true; }
ages() { psql -c "select datname, age(datfrozenxid) from pg_database order by 1"; }
# Move the counter to a transaction id at the start of a pg_xact segment (1,048,576 ids
# each), so that the server creates the segment itself, as the pg_resetwal page recommends.
jump() {
    oldest=$(pg_controldata $D | sed -n "s/^Latest checkpoint.s oldestXID: *//p")
    wrap=$(( oldest + 2147483647 ))
    next=$(( (wrap - $1) / 1048576 * 1048576 ))
    echo "oldest xid $oldest, next xid set to $next, $(( wrap - next )) before wraparound"
    pg_resetwal -D $D -x $next | tail -1
}
initdb -D $D -U postgres >/dev/null 2>&1

echo "== 1. fewer than 40 million transactions before wraparound"
jump 39000000
start
psql -c "create table t (id int)"
ages
echo "-- ten seconds later"
sleep 10
ages
grep -m 2 -o "automatic aggressive vacuum to prevent wraparound of table .*" $D.log || true

echo "== 2. fewer than 3 million, and a prepared transaction forgotten before the jump"
psql -c "begin" -c "insert into t values (1)" -c "prepare transaction '"'"'forgotten'"'"'"
stop
jump 1500000
start
sleep 10
echo "-- ten seconds later, the autovacuum has run"
grep -m 1 -A1 "bypassing nonessential maintenance" $D.log || true
ages
psql -c "insert into t values (2)"
psql -c "select count(*) from t"
psql -c "select gid, age(transaction) from pg_prepared_xacts"
echo "-- the prepared transaction rolled back, then a plain VACUUM"
psql -c "rollback prepared '"'"'forgotten'"'"'"
vacuumdb -h /tmp -U postgres --all > $D.vacuumdb 2>&1
grep "^vacuumdb" $D.vacuumdb; grep -m 2 -A1 "^WARNING" $D.vacuumdb
echo "-- $(grep -c "^WARNING:  bypassing" $D.vacuumdb) tables vacuumed in failsafe mode"
sleep 6
ages
psql -c "insert into t values (2)"
stop
'
