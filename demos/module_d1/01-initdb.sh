#!/usr/bin/env bash
# Clip D1.1: initdb and its options, in a throwaway container (DOCKER=podman for Podman).
# Runs on the host. Nothing touches the lab: the container pgd1-initdb is removed at the end.
set -euo pipefail
docker=${DOCKER:-docker}
$docker run --rm --name pgd1-initdb --user postgres --entrypoint bash \
    docker.io/pgvector/pgvector:pg18 -c '
export PATH=/usr/lib/postgresql/18/bin:$PATH
show() { grep -E "locale provider|default collation|initialized with locale|checksums are"; }

echo "== 1. initdb with its defaults"
initdb -D /tmp/default -U postgres 2>&1 | show
pg_controldata /tmp/default | grep -i checksum

echo "== 2. no checksums, builtin locale provider"
initdb -D /tmp/builtin -U postgres --no-data-checksums \
    --locale-provider=builtin --builtin-locale=C.UTF-8 2>&1 | show
pg_controldata /tmp/builtin | grep -i checksum

echo "== 3. a French libc locale the image does not have"
locale -a | tr "\n" " "; echo
initdb -D /tmp/fr -U postgres --locale=fr_FR.UTF-8 2>&1 | grep -E "error|hint"

echo "== 4. the ICU locale provider, French collation"
initdb -D /tmp/icu -U postgres --locale-provider=icu --icu-locale=fr-FR 2>&1 | show

echo "== 5. the databases of the ICU cluster"
pg_ctl -D /tmp/icu -l /tmp/icu.log -o "-c listen_addresses= -k /tmp" -w start >/dev/null
psql -h /tmp -U postgres -X -c "select datname, datlocprovider, datlocale, datcollate
                                 from pg_database order by datname"
echo "== 6. pg_checksums on a running cluster"
pg_checksums -D /tmp/icu --disable 2>&1 | tail -1
pg_ctl -D /tmp/icu -m fast -w stop >/dev/null

echo "== 7. checksums turned on later, cluster stopped"
pg_checksums -D /tmp/builtin --enable 2>&1 | tail -2
pg_controldata /tmp/builtin | grep -i checksum
'
