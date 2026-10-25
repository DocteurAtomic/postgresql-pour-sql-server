#!/usr/bin/env bash
# Clip D6.5: logical replication, table by table, from a PostgreSQL 17 publisher to a
# PostgreSQL 18 subscriber. Runs on the host (DOCKER=podman for Podman). pgd6-pub17
# (image postgres:17, wal_level = logical) restores pachadataformation; pgd6-sub18 (the
# lab's image) gets the schema only, from pg_dump --schema-only, then the rows of three tables
# by a subscription. Containers, volumes and the network are removed at the end. The lab is
# not touched.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
pub=pgd6-pub17
sub=pgd6-sub18
trap 'cleanup $pub $sub' EXIT
PRIMARY_IMAGE=docker.io/library/postgres:17 start_primary $pub -c wal_level=logical
restore_db $pub
start_primary $sub
pdb() { sql $pub -d pachadataformation "$@"; }
sdb() { sql $sub -d pachadataformation "$@"; }
sessions() {
    for c in $pub $sub; do
        sql $c -d pachadataformation -At -F ' | ' -c "select current_setting('cluster_name'),
            count(*), max(sessionid), (select prix from stage.session where sessionid = 40)
            from stage.session"
    done
}
sub_errors() {
    sdb -c "select subname, apply_error_count, sync_error_count from pg_stat_subscription_stats"
}

echo "== 1. two versions, the schema copied by pg_dump --schema-only"
for c in $pub $sub; do sql $c -At -F ' | ' -c "select current_setting('cluster_name'), current_setting('server_version'), current_setting('wal_level')"; done
$docker exec $sub createdb -U postgres pachadataformation
$docker exec $sub bash -c "PGPASSWORD=course pg_dump -h $pub -U postgres --schema-only pachadataformation \
    | psql -U postgres -d pachadataformation -X -q -v ON_ERROR_STOP=1 >/dev/null"
sdb -c "select count(*) as tables from pg_tables where schemaname not in ('pg_catalog', 'information_schema')"

echo "== 2. the publication: three tables; the replication role may read them"
pdb -c "create publication md6_pub for table stage.stagelangue, stage.session, inscription.facture"
pdb -q -c "grant usage on schema stage, inscription to replicator" \
    -c "grant select on stage.stagelangue, stage.session, inscription.facture to replicator"
pdb -c "select pubname, schemaname, tablename from pg_publication_tables order by 3"

echo "== 3. the subscription: initial copy, then the changes"
sdb -c "create subscription md6_sub
        connection 'host=$pub user=replicator password=$reppass dbname=pachadataformation'
        publication md6_pub"
until [ "$(sdb -At -c "select count(*) from pg_subscription_rel where srsubstate <> 'r'")" = 0 ]; do sleep 1; done
pdb -c "select slot_name, plugin, slot_type, active from pg_replication_slots"
sdb -c "select srrelid::regclass as table_name, srsubstate from pg_subscription_rel order by 1"
pdb -q -c "update stage.session set prix = prix + 10 where sessionid = 40" \
    -c "insert into stage.session (stageid, languecd, datedebut, prix)
        values (1, 'FR', date '2026-11-16', 2100) returning sessionid"
sleep 2
sessions

echo "== 4. the sequence does not follow"
for c in $pub $sub; do
    sql $c -d pachadataformation -At -F ' | ' -c "select current_setting('cluster_name'), last_value, is_called
        from stage.session_sessionid_seq"
done
echo "-- the subscriber takes over and inserts 40 sessions in one statement"
sdb -c "insert into stage.session (stageid, languecd, datedebut, prix)
        select 1, 'FR', date '2026-11-23' + g, 2100 from generate_series(1, 40) g" 2>&1 || true
sdb -c "select min(sessionid) from stage.session"

echo "== 5. a published table without a primary key"
pdb -c "alter publication md6_pub add table inscription.facturecolumnstore"
pdb -c "update inscription.facturecolumnstore set relance = relance where facturecd = 'F0000001'" 2>&1 || true
pdb -c "select relreplident from pg_class where oid = 'inscription.facturecolumnstore'::regclass"
pdb -c "alter publication md6_pub drop table inscription.facturecolumnstore"

echo "== 6. a column added on the publisher only"
pdb -c "alter table stage.session add column md6_room text"
pdb -c "update stage.session set md6_room = 'Paris 2', prix = prix + 10 where sessionid = 40"
sleep 3
logs $sub | grep -E 'missing replicated column' | head -1
sessions
sub_errors
echo "-- the same column added on the subscriber"
sdb -c "alter table stage.session add column md6_room text"
sleep 6
sessions
sub_errors
