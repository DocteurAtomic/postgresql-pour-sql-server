#!/usr/bin/env bash
# Clip D3.2: pg_dump formats, pg_restore -l, selective restore, and the roles that a dump
# does not contain. Runs on the host (DOCKER=podman for Podman), in two throwaway instances,
# pgd3-dump (the source, with pachadataformation) and pgd3-target (an empty instance, as on
# a new server); both are removed at the end. The lab is not touched.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
src=pgd3-dump
dst=pgd3-target
cleanup() { $docker rm -f $src $dst >/dev/null 2>&1 || true; }
trap cleanup EXIT

$docker run -d --name $src -e POSTGRES_PASSWORD=course $image >/dev/null
$docker run -d --name $dst -e POSTGRES_PASSWORD=course $image >/dev/null
wait_ready $src; wait_ready $dst
restore_db $src
# A role of the source instance that owns nothing but has privileges, as an application
# account would.
sql $src -d pachadataformation -q -c "create role comptable login password 'course'" \
    -c "grant usage on schema inscription to comptable" \
    -c "grant select on all tables in schema inscription to comptable"

echo "== 1. one database, four formats"
$docker exec $src bash -c '
cd /tmp
TIMEFORMAT="%2R s"
echo -n "plain     -Fp       "; time pg_dump -U postgres -Fp -f pdf.sql pachadataformation
echo -n "custom    -Fc       "; time pg_dump -U postgres -Fc -f pdf.dump pachadataformation
echo -n "directory -Fd -j 4  "; time pg_dump -U postgres -Fd -j 4 -f pdf.dir pachadataformation
echo -n "tar       -Ft       "; time pg_dump -U postgres -Ft -f pdf.tar pachadataformation
du -sh pdf.sql pdf.dump pdf.dir pdf.tar
ls pdf.dir | head -4; echo "... $(ls pdf.dir | wc -l) files"
head -c 5 pdf.dump; echo
' 2>&1

echo "== 2. the table of contents of a custom dump"
$docker exec $src bash -c '
pg_restore -l /tmp/pdf.dump | grep -c "^[0-9]"
pg_restore -l /tmp/pdf.dump | grep -E " (TABLE|TABLE DATA|INDEX|CONSTRAINT|FK CONSTRAINT|ACL) inscription (facture|nix_facture_relance1|pk_facture|fk_suivifac)" '

echo "== 3. pg_restore -t: the table and its rows, nothing around it"
$docker exec $src createdb -U postgres md3_restore
$docker exec $src pg_restore -U postgres -d md3_restore --no-owner -n inscription -t facture /tmp/pdf.dump 2>&1 \
    | grep -E "ERROR|warning" || true
sql $src -d md3_restore -q -c "create schema inscription"
$docker exec $src pg_restore -U postgres -d md3_restore --no-owner -n inscription -t facture /tmp/pdf.dump 2>&1 \
    | grep -E "ERROR|warning" || true
sql $src -d md3_restore -c "\d inscription.facture" | sed -n '1,3p;/Indexes/,$p'
sql $src -d md3_restore -At -c "select count(*) || ' rows, ' || (select count(*) from pg_indexes where tablename = 'facture') || ' index' from inscription.facture"

echo "== 4. pg_restore -n: the objects of the schema, not the schema itself"
$docker exec $src dropdb -U postgres md3_restore
$docker exec $src createdb -U postgres md3_restore
sql $src -d md3_restore -q -c "create schema inscription"
$docker exec $src pg_restore -U postgres -d md3_restore --no-owner -n inscription /tmp/pdf.dump 2>&1 \
    | grep -E "ERROR|warning" | sort | uniq -c | sed 's/^ *//' || true
sql $src -d md3_restore -At -c "select count(*) || ' tables, ' || (select count(*) from pg_indexes where schemaname = 'inscription') || ' indexes' from pg_tables where schemaname = 'inscription'"

echo "== 5. parallel restore of the directory format, -j 1 then -j 4"
for j in 1 4; do
    $docker exec $src dropdb -U postgres md3_restore
    $docker exec $src createdb -U postgres md3_restore
    echo -n "-j $j  "
    $docker exec $src bash -c "TIMEFORMAT='%2R s'; time pg_restore -U postgres -d md3_restore --no-owner -j $j /tmp/pdf.dir" 2>&1
done

echo "== 6. the same dump on a new instance: the role is missing"
$docker cp $src:/tmp/pdf.dump - | $docker cp - $dst:/tmp
$docker exec $dst createdb -U postgres -T template0 pachadataformation
$docker exec $dst pg_restore -U postgres -d pachadataformation --no-owner /tmp/pdf.dump 2>&1 | grep -E "ERROR|warning" | sort | uniq -c | sed 's/^ *//'  || true
$docker exec $dst pg_restore -U postgres -d pachadataformation --no-owner /tmp/pdf.dump >/dev/null 2>&1 \
    && echo "exit code 0" || echo "exit code $?"

echo "== 7. the roles come from pg_dumpall --globals-only"
$docker exec $src pg_dumpall -U postgres --globals-only > /dev/null
$docker exec $src pg_dumpall -U postgres --globals-only | grep -E "^(CREATE|ALTER) ROLE" | sed -E "s/'SCRAM-SHA-256[^']*'/'SCRAM-SHA-256\$...'/"
$docker exec $dst dropdb -U postgres pachadataformation
$docker exec $src pg_dumpall -U postgres --globals-only | sql $dst -q 2>&1 | grep -v "already exists" || true
$docker exec $dst createdb -U postgres -T template0 pachadataformation
$docker exec $dst pg_restore -U postgres -d pachadataformation --no-owner /tmp/pdf.dump && echo "exit code 0"
sql $dst -d pachadataformation -At -c "select grantee, count(*) from information_schema.role_table_grants where grantee = 'comptable' group by grantee"
