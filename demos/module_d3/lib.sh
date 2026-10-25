# Module D3, helpers sourced by the .sh scripts of the module. Not run on its own.
# Every container and volume of the module is named pgd3-*; each script removes its own at
# the end. The lab (pgcourse) is never touched: the scripts start throwaway instances of the
# same image and restore pachadataformation in them from the dump of setup/install.sh.
docker=${DOCKER:-docker}
image=docker.io/pgvector/pgvector:pg18
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(cd "$here/../.." && pwd)
dump=${DUMP:-$root/setup/pachadataformation.pgdump}
anonymize=${ANONYMIZE:-$root/setup/anonymize.sql}
pgdata=/var/lib/postgresql/18/docker

[ -f "$dump" ] || { echo "Missing $dump: run ./setup/install.sh first." >&2; exit 1; }

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
    $docker cp "$dump" "$1":/tmp/pachadataformation.pgdump
    $docker cp "$anonymize" "$1":/tmp/anonymize.sql
    $docker exec "$1" createdb -U postgres -T template0 pachadataformation
    $docker exec "$1" pg_restore -U postgres -d pachadataformation --no-owner /tmp/pachadataformation.pgdump
    $docker exec "$1" psql -U postgres -d pachadataformation -X -q -v ON_ERROR_STOP=1 -f /tmp/anonymize.sql
    $docker exec "$1" vacuumdb -U postgres --analyze --quiet pachadataformation
    $docker exec "$1" rm /tmp/pachadataformation.pgdump /tmp/anonymize.sql
}

# fill_volume <backup volume> <backup dir> <data volume>: copies a plain-format backup into
# an empty data volume, where the image finds a data directory and starts it as it is.
fill_volume() {
    $docker run --rm --user postgres -v "$1":/backup -v "$3":/var/lib/postgresql \
        --entrypoint bash $image -c "mkdir -p $(dirname $pgdata) && cp -a /backup/$2 $pgdata && chmod 700 $pgdata"
}
