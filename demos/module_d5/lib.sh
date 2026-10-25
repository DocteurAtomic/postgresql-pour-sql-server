# Module D5, helpers sourced by the .sh scripts of the module. Not run on its own.
# Every container of the module is named pgd5-*; each script removes its own at the end.
# The lab (pgcourse) is never touched by these scripts: they start throwaway instances of
# the same image, with the same shared_preload_libraries as the lab.
docker=${DOCKER:-docker}
image=docker.io/pgvector/pgvector:pg18
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(cd "$here/../.." && pwd)
dump=${DUMP:-$root/setup/pachadataformation.pgdump}
anonymize=${ANONYMIZE:-$root/setup/anonymize.sql}
pgdata=/var/lib/postgresql/18/docker

# start_pg <container> [docker run options...]: starts an instance like the lab's.
start_pg() {
    local c=$1; shift
    $docker run -d --name "$c" -e POSTGRES_PASSWORD=course "$@" $image \
        postgres -c shared_preload_libraries=pg_stat_statements >/dev/null
    wait_ready "$c"
}

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

# stop_pg <container> <fast|immediate>: stops the server with pg_ctl; the container stops
# with it, since postgres is its main process. start_again restarts it.
stop_pg() {
    $docker exec --user postgres "$1" pg_ctl stop -D $pgdata -m "$2" >/dev/null 2>&1 || true
    $docker wait "$1" >/dev/null 2>&1 || true
}
start_again() { $docker start "$1" >/dev/null; wait_ready "$1"; }
