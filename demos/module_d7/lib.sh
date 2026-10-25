# Module D7, helpers sourced by the .sh scripts of the module. Not run on its own.
# Every container, volume and network of the module is named pgd7-*; each script removes its
# own at the end. The lab (pgcourse) is never touched. The module uses the official images
# postgres:17 and postgres:18, which are built on the same Debian release (trixie): the
# PostgreSQL 17 binaries of the first run unchanged inside the second.
docker=${DOCKER:-docker}
img17=docker.io/library/postgres:17
img18=docker.io/library/postgres:18
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(cd "$here/../.." && pwd)
dump=${DUMP:-$root/setup/pachadataformation.pgdump}
anonymize=${ANONYMIZE:-$root/setup/anonymize.sql}
# One volume mounted on /var/lib/postgresql holds both data directories, so that
# pg_upgrade --link can make hard links from one to the other (same file system).
pgdata17=/var/lib/postgresql/17/docker
pgdata18=/var/lib/postgresql/18/docker

# wait_ready <container>: until the instance accepts connections on its socket.
wait_ready() {
    local i
    for i in $(seq 1 120); do
        $docker exec "$1" pg_isready -U postgres -q 2>/dev/null && return 0
        sleep 1
    done
    echo "$1 did not start" >&2; $docker logs --tail 20 "$1" >&2; return 1
}

# sql <container> [psql options...]: runs psql as postgres, stdin is the script.
sql() { local c=$1; shift; $docker exec -i "$c" psql -U postgres -X "$@"; }

# as_postgres <container> <command>: runs a shell command as the postgres OS user, in the
# volume, where pg_upgrade may write its files.
as_postgres() { $docker exec -i --user postgres -w /var/lib/postgresql "$1" bash -c "$2"; }

# start_old <container> <volume>: a PostgreSQL 17 instance whose data directory is in the
# shared volume, at /var/lib/postgresql/17/docker.
start_old() {
    $docker run -d --name "$1" -e POSTGRES_PASSWORD=course -e PGDATA=$pgdata17 \
        -v "$2":/var/lib/postgresql $img17 >/dev/null
    wait_ready "$1"
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

# start_new <container> <volume>: a container of the 18 image that does not start a server
# (pg_upgrade wants both servers stopped), with the 17 binaries copied in from the 17 image.
start_new() {
    $docker run -d --name "$1" -v "$2":/var/lib/postgresql --entrypoint sleep $img18 infinity >/dev/null
    $docker run --rm --entrypoint tar $img17 -C / -cf - usr/lib/postgresql/17 usr/share/postgresql/17 \
        | $docker exec -i "$1" tar -C / -xf -
}
