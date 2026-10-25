# Module D6, helpers sourced by the .sh scripts of the module. Not run on its own.
# Every container, volume and network of the module is named pgd6-*; each script removes
# its own at the end. The lab (pgcourse) is never touched: replication needs two instances,
# so the scripts start throwaway instances of the lab's image on their own network,
# pgd6-net, and restore pachadataformation in the primary from the dump of setup/install.sh.
docker=${DOCKER:-docker}
image=${IMAGE:-docker.io/pgvector/pgvector:pg18}
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(cd "$here/../.." && pwd)
dump=${DUMP:-$root/setup/pachadataformation.pgdump}
anonymize=${ANONYMIZE:-$root/setup/anonymize.sql}
pgdata=/var/lib/postgresql/18/docker
net=pgd6-net
# The password of the replication role, for the demos only.
reppass=replication-demo

# wait_ready <container>: until the instance accepts TCP connections.
wait_ready() {
    local i
    for i in $(seq 1 120); do
        $docker exec "$1" pg_isready -U postgres -h 127.0.0.1 -q 2>/dev/null && return 0
        sleep 1
    done
    echo "$1 did not start" >&2; $docker logs --tail 20 "$1" >&2; return 1
}

# sql <container> [psql options...]: runs psql as postgres, stdin is the script.
sql() { local c=$1; shift; $docker exec -i "$c" psql -U postgres -X "$@"; }

# logs <container> [since]: the server log, without the timestamp and pid prefix.
logs() {
    if [ -n "${2:-}" ]; then $docker logs --since "$2" "$1" 2>&1; else $docker logs "$1" 2>&1; fi \
        | sed -E 's/^[0-9-]+ [0-9:.]+ UTC \[[0-9]+\] //'
}

# start_primary <container> [postgres -c options...]: starts an instance like the lab's on
# the module's network, its data directory in the volume <container>-data and its name in
# cluster_name (a standby reports it to the primary as its application_name), with a role
# that may open replication connections and the pg_hba.conf line that lets it in from the
# network. PRIMARY_IMAGE=docker.io/library/postgres:17 starts a version 17 instead.
start_primary() {
    local c=$1; shift
    $docker network inspect $net >/dev/null 2>&1 || $docker network create $net >/dev/null
    $docker run -d --name "$c" --hostname "$c" --network $net -e POSTGRES_PASSWORD=course \
        -v "$c-data":/var/lib/postgresql ${PRIMARY_IMAGE:-$image} \
        postgres -c shared_preload_libraries=pg_stat_statements -c cluster_name="$c" "$@" >/dev/null
    wait_ready "$c"
    sql "$c" -q -c "create role replicator with login replication password '$reppass'"
    $docker exec "$c" bash -c "echo 'host replication replicator samenet scram-sha-256' \
        >> \$(psql -U postgres -At -c 'show hba_file')"
    sql "$c" -q -At -c "select pg_reload_conf()" >/dev/null
}

# restore_db <container>: creates pachadataformation from the dump, as setup/install.sh does.
restore_db() {
    [ -f "$dump" ] || { echo "Missing $dump: run ./setup/install.sh first." >&2; exit 1; }
    $docker cp "$dump" "$1":/tmp/pachadataformation.pgdump
    $docker cp "$anonymize" "$1":/tmp/anonymize.sql
    $docker exec "$1" createdb -U postgres -T template0 pachadataformation
    $docker exec "$1" pg_restore -U postgres -d pachadataformation --no-owner /tmp/pachadataformation.pgdump
    $docker exec "$1" psql -U postgres -d pachadataformation -X -q -v ON_ERROR_STOP=1 -f /tmp/anonymize.sql
    $docker exec "$1" vacuumdb -U postgres --analyze --quiet pachadataformation
    $docker exec "$1" rm /tmp/pachadataformation.pgdump /tmp/anonymize.sql
}

# make_standby <primary> <standby> <slot> [postgres -c options...]: clones the primary with
# pg_basebackup -R into the volume <standby>-data, creating the physical slot <slot>, then
# starts the standby on that data directory, its name in cluster_name. STANDBY_OPTS adds
# options to its docker run (--cap-add NET_ADMIN for clip D6.3).
make_standby() {
    local p=$1 s=$2 slot=$3; shift 3
    $docker volume create "$s-data" >/dev/null
    $docker run --rm --network $net --user postgres -e PGPASSWORD=$reppass \
        -v "$s-data":/var/lib/postgresql --entrypoint bash $image -c "
        mkdir -p $(dirname $pgdata) &&
        pg_basebackup -h $p -U replicator -D $pgdata -R -C -S $slot -X stream -c fast &&
        chmod 700 $pgdata"
    $docker run -d --name "$s" --hostname "$s" --network $net -e POSTGRES_PASSWORD=course \
        ${STANDBY_OPTS:-} -v "$s-data":/var/lib/postgresql $image \
        postgres -c shared_preload_libraries=pg_stat_statements -c cluster_name="$s" "$@" >/dev/null
    wait_ready "$s"
}

# wait_replayed <primary> <standby>: until the standby has replayed what the primary wrote.
wait_replayed() {
    local lsn i
    lsn=$(sql "$1" -At -c "select pg_current_wal_lsn()")
    for i in $(seq 1 60); do
        [ "$(sql "$2" -At -c "select pg_last_wal_replay_lsn() >= '$lsn'")" = t ] && return 0
        sleep 0.5
    done
    echo "$2 did not catch up with $1" >&2; return 1
}

# cleanup <containers...>: removes the containers, their -data volumes and the network.
cleanup() {
    local c
    for c in "$@"; do
        $docker rm -f "$c" >/dev/null 2>&1 || true
        $docker volume rm -f "$c-data" >/dev/null 2>&1 || true
    done
    $docker network rm $net >/dev/null 2>&1 || true
}
