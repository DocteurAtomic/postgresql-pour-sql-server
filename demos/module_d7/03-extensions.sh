#!/usr/bin/env bash
# Clip D7.3: extensions across pg_upgrade. A 17 instance with pgvector (installed from the
# PGDG repository the image declares, network needed) and pg_stat_statements; pg_upgrade
# --check refuses while the 18 binaries lack pgvector, then the upgrade leaves
# pg_stat_statements at its 17 version. Runs on the host (DOCKER=podman for Podman), in the
# throwaway containers pgd7-ext17 and pgd7-ext18 on the volume pgd7-ext; all are removed at
# the end. The lab is not touched.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
vol=pgd7-ext
cleanup() {
    $docker rm -f -v pgd7-ext17 pgd7-ext18 >/dev/null 2>&1 || true
    $docker volume rm -f $vol >/dev/null 2>&1 || true
}
trap cleanup EXIT
upgrade="export PGBINOLD=/usr/lib/postgresql/17/bin PGBINNEW=/usr/lib/postgresql/18/bin
         export PGDATAOLD=$pgdata17 PGDATANEW=$pgdata18"
apt_install() {
    $docker exec "$1" bash -c "apt-get update -qq >/dev/null && apt-get install -y -qq $2 >/dev/null 2>&1"
}

echo "== 1. the 17 instance, with two extensions"
start_old pgd7-ext17 $vol
apt_install pgd7-ext17 postgresql-17-pgvector
sql pgd7-ext17 -q -c "create database md7ext"
sql pgd7-ext17 -d md7ext -q -c "create extension vector" -c "create extension pg_stat_statements" \
    -c "create table document (id int primary key, embedding vector(3))" \
    -c "insert into document values (1, '[1,2,3]'), (2, '[4,5,6]')"
sql pgd7-ext17 -d md7ext -c "select extname, extversion from pg_extension order by extname"
$docker stop -t 60 pgd7-ext17 >/dev/null
$docker rm -v pgd7-ext17 >/dev/null

echo "== 2. pg_upgrade --check, the 18 binaries without pgvector"
start_new pgd7-ext18 $vol
as_postgres pgd7-ext18 "initdb -D $pgdata18 -U postgres --no-data-checksums >/dev/null 2>&1
    $upgrade; pg_upgrade --check --link | tail -8" || echo "exit code $?"
as_postgres pgd7-ext18 'cat $(ls -d 18/docker/pg_upgrade_output.d/*/ | tail -1)loadable_libraries.txt'

echo "== 3. pgvector for 18 installed, the upgrade"
apt_install pgd7-ext18 postgresql-18-pgvector
as_postgres pgd7-ext18 "$upgrade; pg_upgrade --link > /tmp/upgrade.log; grep -A4 'extension updates' /tmp/upgrade.log; ls; cat update_extensions.sql"

echo "== 4. start 18, the versions, then the update script"
as_postgres pgd7-ext18 "pg_ctl -D $pgdata18 -l /var/lib/postgresql/18.log -w start >/dev/null"
sql pgd7-ext18 -d md7ext -c "select extname, extversion, default_version
                             from pg_extension join pg_available_extensions on name = extname
                             order by extname"
as_postgres pgd7-ext18 "psql -X -q -f update_extensions.sql postgres"
sql pgd7-ext18 -d md7ext -c "select extname, extversion from pg_extension order by extname" \
    -c "select id, embedding from document order by id"
