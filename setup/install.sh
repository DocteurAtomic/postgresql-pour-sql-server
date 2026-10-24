#!/usr/bin/env bash
# Downloads the pachadataformation dump, checks it, starts the lab and restores the database.
# Usage: ./setup/install.sh        (COMPOSE="podman compose" ./setup/install.sh with Podman)
set -euo pipefail
cd "$(dirname "$0")/.."

url='https://files.pachadata.com/public/api/raw?hash=detKgDWpmgcSvphD4YTPvQ&file=%2Fsample-databases%2FPachadataFormation%2FPostgreSQL%2Fpachadataformation.pgdump'
sum=96df4039dcd2faffe59707e61031e9ccaed40f482827daa346f23b448eca4197
dump=setup/pachadataformation.pgdump
compose=${COMPOSE:-docker compose}

if [ ! -f "$dump" ]; then
    echo "Downloading the database dump (24 MB)..."
    curl -fL --retry 3 -o "$dump.part" "$url"
    mv "$dump.part" "$dump"
fi
if command -v sha256sum >/dev/null; then got=$(sha256sum "$dump" | cut -d' ' -f1)
else got=$(shasum -a 256 "$dump" | cut -d' ' -f1); fi
if [ "$got" != "$sum" ]; then
    echo "Checksum mismatch for $dump: delete it and run this script again." >&2
    exit 1
fi

$compose up -d --wait
if $compose exec -T db psql -U postgres -XAtc "select 1 from pg_database where datname = 'pachadataformation'" | grep -q 1; then
    echo "The database pachadataformation already exists: nothing to restore."
    exit 0
fi
$compose exec -T db createdb -U postgres -T template0 pachadataformation
$compose exec -T db pg_restore -U postgres -d pachadataformation --no-owner /setup/pachadataformation.pgdump
$compose exec -T db psql -U postgres -d pachadataformation -X -q -v ON_ERROR_STOP=1 -f /setup/anonymize.sql
$compose exec -T db vacuumdb -U postgres --analyze pachadataformation
$compose exec -T db psql -U postgres -d pachadataformation -XAtc \
    "select count(*) || ' tables restored' from pg_tables where schemaname not in ('pg_catalog', 'information_schema')"
