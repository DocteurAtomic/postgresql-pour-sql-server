# Module D8, helpers sourced by the .sh scripts of the module. Not run on its own.
# Every container, volume and network of the module is named pgd8-*; each script removes its
# own at the end. The lab (pgcourse) is never touched.
#
# The source is a SQL Server instance with the PachaDataFormation database, read only:
#   MSSQL_SA_PASSWORD  password of the login (required, read from the environment, never
#                      written in a script or on a command line)
#   MSSQL_USER         login (default sa; in production, a read-only login of its own)
#   MSSQL_CONTAINER    container where sqlcmd and bcp run (default sql2022)
#   MSSQL_HOST         address of the instance seen from a container (default
#                      host.containers.internal, the host under Podman; with Docker on
#                      Linux, set DOCKER_HOST_GATEWAY=1 to map it to the host gateway)
#   MSSQL_PORT         port of the instance on the host (default 11433)
#   MSSQL_DB           source database (default PachaDataFormation)
docker=${DOCKER:-docker}
image=docker.io/pgvector/pgvector:pg18
pgloader_image=${PGLOADER_IMAGE:-ghcr.io/dimitri/pgloader:latest}
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

: "${MSSQL_SA_PASSWORD:?set MSSQL_SA_PASSWORD to the password of the SQL Server login}"
export MSSQL_USER=${MSSQL_USER:-sa}
export MSSQL_CONTAINER=${MSSQL_CONTAINER:-sql2022}
export MSSQL_HOST=${MSSQL_HOST:-host.containers.internal}
export MSSQL_PORT=${MSSQL_PORT:-11433}
export MSSQL_DB=${MSSQL_DB:-PachaDataFormation}
# Passed to the containers by name (-e NAME), so that the value never shows in a command.
export SQLCMDPASSWORD=$MSSQL_SA_PASSWORD
export MSSQL_PASSWORD=$MSSQL_SA_PASSWORD
add_host=()
[ -n "${DOCKER_HOST_GATEWAY:-}" ] && add_host=(--add-host "$MSSQL_HOST:host-gateway")

# wait_ready <container>: until the instance accepts TCP connections.
wait_ready() {
    local i
    for i in $(seq 1 120); do
        $docker exec "$1" pg_isready -U postgres -h 127.0.0.1 -q 2>/dev/null && return 0
        sleep 1
    done
    echo "$1 did not start" >&2; $docker logs --tail 20 "$1" >&2; return 1
}

# start_pg <container> <network> [postgres options...]: a throwaway PostgreSQL 18 of the lab
# image, on the module network, with an empty database pachadata.
start_pg() {
    local c=$1 net=$2; shift 2
    $docker run -d --name "$c" --network "$net" "${add_host[@]}" -e POSTGRES_PASSWORD=course \
        $image "$@" >/dev/null
    wait_ready "$c"
    $docker exec "$c" createdb -U postgres pachadata
}

# sql <container> [psql options...]: runs psql as postgres on pachadata, stdin is the script.
sql() { local c=$1; shift; $docker exec -i "$c" psql -U postgres -d pachadata -X "$@"; }

# mssql [sqlcmd options...]: runs sqlcmd on the source, stdin is the script.
mssql() {
    $docker exec -i -e SQLCMDPASSWORD "$MSSQL_CONTAINER" /opt/mssql-tools18/bin/sqlcmd \
        -S localhost -U "$MSSQL_USER" -C -d "$MSSQL_DB" -W -s'|' "$@"
}

# pgloader <network> <load file> [pgloader options...]: runs pgloader from its image. The load
# file reads the connection from the environment ({{MSSQL_HOST}}, {{MSSQL_PASSWORD}}...).
pgloader() {
    local net=$1 file=$2; shift 2
    $docker run --rm --network "$net" "${add_host[@]}" \
        -e MSSQL_USER -e MSSQL_PASSWORD -e MSSQL_HOST -e MSSQL_PORT -e MSSQL_DB \
        -v "$here/pgloader":/load:ro,Z $pgloader_image pgloader "$@" "/load/$file"
}

# bcp_out <query> <file in the SQL Server container>: character mode, UTF-8, tab separated.
# bcp reads the password on its standard input: it never appears on its command line.
bcp_out() {
    $docker exec -i -e SQLCMDPASSWORD "$MSSQL_CONTAINER" bash -c \
        'printf "%s\n" "$SQLCMDPASSWORD" | /opt/mssql-tools18/bin/bcp "$0" queryout "$1" \
             -S localhost -U "'"$MSSQL_USER"'" -d "'"$MSSQL_DB"'" -u -c -C 65001 -t "\t" \
         | grep -E "rows copied|Error|Clock"' "$1" "$2"
}

# load_training <container> <network>: the training tables by pgloader (04-load.load, whose
# target is pgd8-target), quietly; prints the log and stops on an error.
load_training() {
    local log
    log=$(pgloader "$2" 04-load.load 2>&1) || { echo "$log"; return 1; }
    if grep -qE 'ERROR|FATAL' <<<"$log"; then echo "$log"; return 1; fi
}

# load_ville <container>: Reference.ville by bcp and COPY, as 04-load.sh shows it.
load_ville() {
    local f=/tmp/pgd8_ville_$$.tsv
    sql "$1" -q < "$here/04-ville.sql"
    bcp_out "SELECT VilleId, RegionId, NomVille, CodePostal, CodeINSEE, CodeRegion, Latitude, Longitude,
                    Eloignement, PointGeographique.STAsText(), PaysCD FROM Reference.ville" $f >/dev/null
    $docker exec "$MSSQL_CONTAINER" cat $f \
        | sql "$1" -q -c "copy reference.ville from stdin (format csv, delimiter E'\t')"
    $docker exec "$MSSQL_CONTAINER" rm -f $f
}
