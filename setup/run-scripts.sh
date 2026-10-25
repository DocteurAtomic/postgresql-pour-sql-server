#!/usr/bin/env bash
# Runs every demo and exercise script of the lab in order, stopping at the first error.
# A script whose first lines contain "-- ci: skip" (two sessions, instance changes) is skipped.
# The exercises of a module run before its demos' 99-cleanup.sql, since they may read what
# the module's 00-setup.sql created.
# Usage: ./setup/run-scripts.sh [module folder name ...]
set -euo pipefail
cd "$(dirname "$0")/.."
compose=${COMPOSE:-docker compose}
modules=("$@")
if [ ${#modules[@]} -eq 0 ]; then
    modules=($(ls demos exercises 2>/dev/null | grep '^module_' | sort -u || true))
fi
for m in "${modules[@]}"; do
    for f in $(ls demos/$m/*.sql 2>/dev/null | grep -v '/99-' || true) \
             $(ls exercises/$m/*.sql 2>/dev/null || true) \
             $(ls demos/$m/99-*.sql 2>/dev/null || true); do
        if head -5 "$f" | grep -q -- '-- ci: skip'; then echo "skip $f"; continue; fi
        echo "run  $f"
        $compose exec -T db psql -U postgres -d pachadataformation -X -q -v ON_ERROR_STOP=1 -f "/$f" >/dev/null
    done
done
