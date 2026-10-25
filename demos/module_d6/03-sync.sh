#!/usr/bin/env bash
# Clip D6.3: synchronous and asynchronous replication, and what the wait costs. Runs on the
# host (DOCKER=podman for Podman). pgd6-primary has two standbys, pgd6-standby1 and
# pgd6-standby2. pgd6-standby1 plays a standby in another data center: it gets the
# NET_ADMIN capability, iproute2 from the Debian repository (network access needed), and
# a 10 ms delay on what it sends (netem), so that each acknowledgement takes 10 ms more.
# The commit latency is the average of pgbench, one client inserting one row per
# transaction for 5 seconds. Containers, volumes and the network are removed at the end.
# The lab is not touched.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
p=pgd6-primary
s1=pgd6-standby1
s2=pgd6-standby2
trap 'cleanup $p $s1 $s2' EXIT
start_primary $p
sql $p -q -c "create table md6_commit (id bigint generated always as identity, at timestamptz default now())"
$docker exec $p bash -c "echo 'insert into md6_commit default values;' > /tmp/commit.sql"
STANDBY_OPTS="--cap-add NET_ADMIN" make_standby $p $s1 standby1
make_standby $p $s2 standby2
$docker exec $s1 bash -c "apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq iproute2 >/dev/null 2>&1"

# set_conf <name> <value>: ALTER SYSTEM on the primary, then reload.
set_conf() {
    sql $p -At -c "alter system set $1 = '$2'" -c "select pg_reload_conf()" >/dev/null
    sleep 1
}
commit_latency() {
    printf '%-40s %s\n' "$1" "$($docker exec $p pgbench -U postgres -n -c 1 -T 5 -f /tmp/commit.sql postgres 2>&1 \
        | sed -n 's/^latency average = //p')"
}
states() {
    sql $p -c "select application_name, sync_priority, sync_state from pg_stat_replication order by 1"
}

echo "== 1. a 10 ms delay on what $s1 sends"
$docker exec $s1 tc qdisc add dev eth0 root netem delay 10ms
$docker exec $s1 tc qdisc show dev eth0

echo "== 2. asynchronous: synchronous_standby_names is empty"
states
commit_latency "synchronous_commit = on"

echo "== 3. one synchronous standby, the distant one"
set_conf synchronous_standby_names '"pgd6-standby1"'
states
for level in off local remote_write on remote_apply; do
    set_conf synchronous_commit $level
    commit_latency "synchronous_commit = $level"
done
set_conf synchronous_commit on

echo "== 4. a quorum: ANY 1 of the two standbys"
set_conf synchronous_standby_names 'ANY 1 ("pgd6-standby1", "pgd6-standby2")'
states
commit_latency "ANY 1, both standbys up"
$docker stop $s2 >/dev/null
commit_latency "ANY 1, $s2 stopped"

echo "== 5. no synchronous standby left: the commit waits"
$docker stop $s1 >/dev/null
sql $p -c "\timing on" -c "insert into md6_commit default values returning id" 2>&1 &
sleep 3
sql $p -c "select pid, state, wait_event_type, wait_event, left(query, 40) as query
           from pg_stat_activity where wait_event = 'SyncRep'"
echo "-- cancel the waiting session"
sql $p -At -c "select pg_cancel_backend(pid) from pg_stat_activity where wait_event = 'SyncRep'" >/dev/null
wait
echo "-- the row is there, committed locally"
sql $p -c "select max(id) as last_id from md6_commit"
echo "-- one transaction may decide not to wait"
sql $p -c "begin" -c "set local synchronous_commit = local" \
    -c "insert into md6_commit default values returning id" -c "commit"
