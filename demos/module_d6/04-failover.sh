#!/usr/bin/env bash
# Clip D6.4: failover by hand. Runs on the host (DOCKER=podman for Podman). pgd6-primary
# crashes (podman kill), pgd6-standby is promoted with pg_promote(); the old primary comes
# back as a second primary, then is rewound with pg_rewind and follows the new one. An
# application container, pgd6-app, connects with a libpq string that lists both hosts and
# asks for the one that accepts writes. Containers, volumes and the network are removed at
# the end. The lab is not touched.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
p=pgd6-primary
s=pgd6-standby
app=pgd6-app
trap 'cleanup $p $s $app' EXIT
start_primary $p
restore_db $p
make_standby $p $s standby1
$docker run -d --name $app --network $net --entrypoint sleep $image infinity >/dev/null
conn="host=$p,$s user=postgres password=course dbname=pachadataformation"
conn="$conn target_session_attrs=read-write connect_timeout=2"

# app [psql options...]: the application connects with the two-host string.
app() { $docker exec -i $app psql "$conn" -X "$@"; }
where() { app -At -F ' | ' -c "select current_setting('cluster_name'), pg_is_in_recovery()" 2>&1 || true; }
roles() {
    for c in $p $s; do
        sql $c -At -F ' | ' -c "select current_setting('cluster_name'), pg_is_in_recovery(),
                                       (select timeline_id from pg_control_checkpoint())" 2>/dev/null \
            || echo "$c | down"
    done
}

echo "== 1. the application string: $conn"
where

echo "== 2. the primary crashes"
$docker kill $p >/dev/null
where
sleep 2
logs $s | grep -E 'could not (connect|receive)' | tail -1 | cut -c1-110
sql $s -At -c "select pg_is_in_recovery()"

echo "== 3. pg_promote() on the standby"
t=$(date -u +%FT%TZ)
sql $s -c "select pg_promote()"
logs $s $t | grep -E 'promote|selected new timeline|archive recovery complete|ready to accept'
sql $s -q -c "checkpoint"
roles
where
app -c "update stage.session set prix = prix + 100 where sessionid = 40"

echo "== 4. the old primary restarts: two primaries"
$docker start $p >/dev/null
wait_ready $p
roles
where
sql $p -d pachadataformation -c "update stage.session set prix = 0 where sessionid = 41"
for c in $p $s; do
    sql $c -d pachadataformation -At -F ' | ' -c "select current_setting('cluster_name'),
        string_agg(sessionid || ' ' || prix, ', ' order by sessionid)
        from stage.session where sessionid in (40, 41)"
done

echo "== 5. stop the old primary, rewind it from the new one"
$docker exec --user postgres $p pg_ctl stop -D $pgdata -m fast >/dev/null 2>&1 || true
$docker wait $p >/dev/null 2>&1 || true
$docker exec $s psql -U postgres -X -c "select pg_create_physical_replication_slot('old_primary')" >/dev/null
$docker run --rm --network $net --user postgres -v $p-data:/var/lib/postgresql --entrypoint bash $image -c "
    pg_controldata $pgdata | grep -E 'Database cluster state|checksum version|TimeLineID'
    pg_rewind --target-pgdata=$pgdata -R \
        --source-server='host=$s user=postgres password=course dbname=postgres' 2>&1
    ls $pgdata | grep signal
    grep -o \"primary_conninfo = 'user=postgres password=[^ ]*\" $pgdata/postgresql.auto.conf
    # -R wrote the source server's string; the standby connects with the replication role.
    cat >> $pgdata/postgresql.auto.conf <<CONF
primary_conninfo = 'host=$s user=replicator password=$reppass'
primary_slot_name = 'old_primary'
CONF"

echo "== 6. the old primary starts as a standby of the new one"
$docker start $p >/dev/null
wait_ready $p
sql $p -At -c "select pg_is_in_recovery()"
wait_replayed $s $p
sql $s -c "select application_name, state, sync_state from pg_stat_replication"
sql $p -c "select status, sender_host, received_tli from pg_stat_wal_receiver"
sql $p -d pachadataformation -At -F ' | ' -c "select current_setting('cluster_name'),
    string_agg(sessionid || ' ' || prix, ', ' order by sessionid)
    from stage.session where sessionid in (40, 41)"
where
