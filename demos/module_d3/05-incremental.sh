#!/usr/bin/env bash
# Clip D3.5: incremental backups (summarize_wal, pg_basebackup --incremental,
# pg_combinebackup), then pg_verifybackup and a test restore. Runs on the host
# (DOCKER=podman for Podman), in the throwaway containers pgd3-source and pgd3-restore,
# with the volumes pgd3-backup and pgd3-restore-data; all are removed at the end. The lab is
# not touched.
set -euo pipefail
cd "$(dirname "$0")"
. ./lib.sh
src=pgd3-source
dst=pgd3-restore
cleanup() {
    $docker rm -f $src $dst >/dev/null 2>&1 || true
    $docker volume rm -f pgd3-backup pgd3-restore-data >/dev/null 2>&1 || true
}
trap cleanup EXIT
backup() { $docker exec --user postgres $src pg_basebackup -U postgres -Fp -X stream -c fast "$@"; }

$docker run -d --name $src -e POSTGRES_PASSWORD=course -v pgd3-backup:/backup $image >/dev/null
wait_ready $src
$docker exec $src chown postgres /backup
restore_db $src

echo "== 1. no incremental backup without WAL summaries"
backup -D /backup/full -l "d3 full"
backup -D /backup/incr1 --incremental=/backup/full/backup_manifest 2>&1 || true
sql $src -c "select name, setting, unit, context from pg_settings where name like '%summar%'"
sql $src -q -c "alter system set summarize_wal = on" -c "select pg_reload_conf()" >/dev/null
sleep 2
sql $src -c "select summarized_tli, summarized_lsn, summarizer_pid is not null as running
             from pg_get_wal_summarizer_state()"
$docker exec $src rm -rf /backup/full

echo "== 2. a full backup, then two days of changes, each followed by an incremental backup"
backup -D /backup/full -l "d3 full"
sql $src -d pachadataformation -q -c "update stage.session set prix = prix + 10 where sessionid % 3 = 0"
backup -D /backup/incr1 --incremental=/backup/full/backup_manifest -l "d3 incremental 1"
sql $src -d pachadataformation -q -c "update inscription.facture set relance = relance + 1 where datefacture >= '2020-01-01'"
backup -D /backup/incr2 --incremental=/backup/incr1/backup_manifest -l "d3 incremental 2"
$docker exec $src bash -c 'cd /backup
for b in full incr1 incr2; do
    printf "%-6s %5s  %4s INCREMENTAL files, pg_wal %s\n" $b "$(du -sh $b | cut -f1)" \
        "$(find $b -name "INCREMENTAL.*" | wc -l)" "$(du -sh $b/pg_wal | cut -f1)"
done
grep -E "INCREMENTAL FROM|LABEL" incr2/backup_label'
sql $src -d pachadataformation < 05-check-data.sql

echo "== 3. pg_combinebackup: the whole chain, oldest first"
$docker exec --user postgres $src pg_combinebackup /backup/full /backup/incr2 -o /backup/broken 2>&1 || true
$docker exec --user postgres $src pg_combinebackup /backup/full /backup/incr1 /backup/incr2 -o /backup/combined
$docker exec $src du -sh /backup/combined

echo "== 4. pg_verifybackup: the manifest against the files"
$docker exec --user postgres $src pg_verifybackup /backup/combined
file=$(sql $src -d pachadataformation -At -c "select pg_relation_filepath('inscription.facture')")
$docker exec --user postgres $src bash -c "
cp -a /backup/full /backup/damaged
printf 'xxxxxxxx' | dd of=/backup/damaged/$file bs=1 seek=100000 conv=notrunc status=none
rm /backup/damaged/global/pg_control
pg_verifybackup /backup/damaged 2>&1 | sed 's/^/  /'
rm -rf /backup/damaged" || true

echo "== 5. the test restore: start an instance on the combined backup"
$docker volume create pgd3-restore-data >/dev/null
fill_volume pgd3-backup combined pgd3-restore-data
$docker run -d --name $dst -e POSTGRES_PASSWORD=course -v pgd3-restore-data:/var/lib/postgresql $image >/dev/null
wait_ready $dst
sql $dst -d pachadataformation < 05-check-data.sql
$docker exec $dst pg_dump -U postgres -f /dev/null pachadataformation && echo "pg_dump to /dev/null: every row of every table read"
