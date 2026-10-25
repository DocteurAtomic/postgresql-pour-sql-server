#!/usr/bin/env bash
# Clip D2.4: pgaudit, which the lab image does not contain. Runs on the host, in a
# throwaway container pgd2-audit (DOCKER=podman for Podman), removed at the end. The
# container is the image of the lab plus the package postgresql-18-pgaudit, installed at
# start from the PGDG repository that the image already declares (signed by its key); it
# needs network access. The lab is not touched. The key is a demonstration value.
set -euo pipefail
docker=${DOCKER:-docker}
name=pgd2-audit
image=docker.io/pgvector/pgvector:pg18
cleanup() { $docker rm -f $name >/dev/null 2>&1; }
trap cleanup EXIT
sql() { $docker exec -i $name sh -c 'psql -U postgres -X -v ON_ERROR_STOP=1 2>&1'; }
mark() { seen=$($docker logs $name 2>&1 | wc -l); }
audit_log() { sleep 1; $docker logs $name 2>&1 | tail -n +$((seen + 1)) | grep -oE 'AUDIT: .*' || true; }

$docker run -d --name $name -e POSTGRES_PASSWORD=course --entrypoint bash $image -c '
    apt-get update -qq >/dev/null && apt-get install -y -qq postgresql-18-pgaudit >/dev/null
    exec docker-entrypoint.sh postgres -c shared_preload_libraries=pgaudit' >/dev/null
until $docker exec $name pg_isready -U postgres -h 127.0.0.1 -q 2>/dev/null; do sleep 2; done

echo "== the extension, loaded at start"
sql <<'SQL'
create extension pgaudit;
create extension pgcrypto;
select extname, extversion from pg_extension where extname in ('pgaudit', 'pgcrypto') order by 1;
alter system set pgaudit.log = 'ddl, role, read';
select pg_reload_conf();
SQL

echo "== what an administrator does, then reads"
mark
sql <<'SQL'
create role md2_app login password 'demo-app';
create table md2_contact (contactid int, telephone_chiffre bytea);
grant select on md2_contact to md2_app;
insert into md2_contact values (1, pgp_sym_encrypt('01 02 03 04 05', 'demo-key'));
select contactid, pgp_sym_decrypt(telephone_chiffre, 'demo-key') from md2_contact;
SQL
echo "== the server log"
audit_log
