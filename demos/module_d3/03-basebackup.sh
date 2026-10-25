#!/usr/bin/env bash
# Clip D3.3: pg_basebackup, a physical backup of the whole instance, then its restore on a
# second instance. Runs on the host (DOCKER=podman for Podman), in two throwaway containers,
# pgd3-source and pgd3-restore, with the volumes pgd3-backup and pgd3-restore-data; all are
# removed at the end. The lab is not touched.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
src=pgd3-source
dst=pgd3-restore
cleanup() {
    $docker rm -f $src $dst >/dev/null 2>&1 || true
    $docker volume rm -f pgd3-backup pgd3-restore-data >/dev/null 2>&1 || true
}
trap cleanup EXIT

$docker run -d --name $src -e POSTGRES_PASSWORD=course -v pgd3-backup:/backup $image >/dev/null
wait_ready $src
$docker exec $src chown postgres /backup
restore_db $src

echo "== 1. the databases of the source instance"
sql $src -c "select oid, datname, pg_size_pretty(pg_database_size(oid)) as size
             from pg_database order by oid"

echo "== 2. pg_basebackup, plain format, WAL streamed, fast checkpoint"
$docker exec --user postgres $src pg_basebackup -U postgres -D /backup/full -Fp -X stream \
    -c fast -l "d3 full backup" -P 2>&1 | tr '\r' '\n' | tail -1
$docker exec $src bash -c 'cd /backup/full; ls; echo "--- backup_label"; cat backup_label
echo "--- base/"; du -sh base/*; echo "--- total"; du -sh .
echo "--- backup_manifest"; head -c 300 backup_manifest; echo " ..."'

echo "== 3. a database name in the connection string changes nothing"
$docker exec --user postgres $src pg_basebackup -d "dbname=pachadataformation user=postgres" \
    -D /backup/one-db -Fp -X stream -c fast
$docker exec $src bash -c 'ls /backup/one-db/base; du -sh /backup/one-db'

echo "== 4. tar format, compressed"
$docker exec --user postgres $src pg_basebackup -U postgres -D /backup/tar -Ft -z -X stream -c fast
$docker exec $src bash -c 'cd /backup/tar; ls -sh'

echo "== 5. restore: copy the files, start the server"
$docker volume create pgd3-restore-data >/dev/null
fill_volume pgd3-backup full pgd3-restore-data
$docker run -d --name $dst -e POSTGRES_PASSWORD=course -v pgd3-restore-data:/var/lib/postgresql $image >/dev/null
wait_ready $dst
$docker logs $dst 2>&1 | grep -E "starting backup recovery|redo (starts|done)|consistent recovery state|ready to accept" | sed -E 's/^[0-9-]+ [0-9:.]+ UTC \[[0-9]+\] //'
sql $dst -c "select datname from pg_database order by oid"
sql $dst -d pachadataformation -c "select count(*) as factures from inscription.facture"
