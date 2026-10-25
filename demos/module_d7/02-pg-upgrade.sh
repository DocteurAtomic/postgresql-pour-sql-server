#!/usr/bin/env bash
# Clip D7.2: pg_upgrade from 17 to 18, --check, the checksum refusal, --copy against --link,
# and the optimizer statistics that 18 carries over. Runs on the host (DOCKER=podman for
# Podman), in two throwaway containers on one volume, pgd7-upgrade: pgd7-old (postgres:17)
# and pgd7-new (postgres:18, plus the 17 binaries copied from the 17 image). All are removed
# at the end. The lab is not touched.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
vol=pgd7-upgrade
cleanup() {
    $docker rm -f -v pgd7-old pgd7-new >/dev/null 2>&1 || true
    $docker volume rm -f $vol >/dev/null 2>&1 || true
}
trap cleanup EXIT
upgrade="export PGBINOLD=/usr/lib/postgresql/17/bin PGBINNEW=/usr/lib/postgresql/18/bin
         export PGDATAOLD=$pgdata17 PGDATANEW=$pgdata18"

echo "== 1. the old instance: PostgreSQL 17, pachadataformation restored"
start_old pgd7-old $vol
restore_db pgd7-old
sql pgd7-old -d pachadataformation -q < "$here/02-stats-before.sql"
$docker stop -t 60 pgd7-old >/dev/null
$docker rm -v pgd7-old >/dev/null

echo "== 2. the new binaries: the 18 image, and the 17 binaries copied in"
start_new pgd7-new $vol
$docker exec pgd7-new ls /usr/lib/postgresql
as_postgres pgd7-new 'ls; /usr/lib/postgresql/17/bin/postgres --version; postgres --version'

echo "== 3. initdb 18 with its defaults, then pg_upgrade --check"
as_postgres pgd7-new "initdb -D $pgdata18 -U postgres 2>&1 | grep -i checksums"
as_postgres pgd7-new "$upgrade; pg_upgrade --check --link" || echo "exit code $?"

echo "== 4. initdb 18 without checksums, pg_upgrade --check again"
as_postgres pgd7-new "rm -rf $pgdata18; initdb -D $pgdata18 -U postgres --no-data-checksums 2>&1 | grep -i checksums"
as_postgres pgd7-new "$upgrade; pg_upgrade --check --link | tail -3"

echo "== 5. pg_upgrade --copy, into a second new data directory"
as_postgres pgd7-new "initdb -D /var/lib/postgresql/18/copy -U postgres --no-data-checksums >/dev/null 2>&1
    $upgrade; export PGDATANEW=/var/lib/postgresql/18/copy
    TIMEFORMAT='pg_upgrade --copy: %R s'; time pg_upgrade --copy >/dev/null
    du -sh 17/docker 18/copy; du -sh .; rm -rf 18/copy delete_old_cluster.sh"

echo "== 6. pg_upgrade --link"
as_postgres pgd7-new "$upgrade
    TIMEFORMAT='pg_upgrade --link: %R s'; time pg_upgrade --link > /tmp/upgrade.log
    sed -n '/^Adding/,\$p' /tmp/upgrade.log
    ls 17/docker/global | grep pg_control; du -sh 17/docker 18/docker; du -sh ."

echo "== 7. start 18, the same file in both data directories"
as_postgres pgd7-new "pg_ctl -D $pgdata18 -l /var/lib/postgresql/18.log -w start >/dev/null"
f=$(sql pgd7-new -d pachadataformation -At -c "select pg_relation_filepath('inscription.facture')")
as_postgres pgd7-new "stat -c '%h links  inode %i  %n' 17/docker/$f 18/docker/$f"

echo "== 8. the statistics right after the upgrade"
sql pgd7-new -d pachadataformation -q < "$here/02-stats-after.sql"

echo "== 9. vacuumdb, missing statistics only"
as_postgres pgd7-new "vacuumdb -U postgres --all --analyze-in-stages --missing-stats-only 2>&1 | grep pachadataformation"
sql pgd7-new -d pachadataformation -c "select relname, n_live_tup from pg_stat_user_tables
                                        where last_analyze is not null order by relname"
sql pgd7-new -d pachadataformation -q < "$here/02-stats-after.sql"

echo "== 10. vacuumdb, analyze only, for the cumulative statistics"
as_postgres pgd7-new "vacuumdb -U postgres --all --analyze-only --quiet"
sql pgd7-new -d pachadataformation -c "select count(*) filter (where last_analyze is not null) as analyzed,
                                               count(*) as tables
                                        from pg_stat_user_tables"
