#!/usr/bin/env bash
# Clip D5.2: the timeouts a DBA sets for an application role, so that a forgotten
# transaction ends by itself. Runs on the host (DOCKER=podman for Podman), in a throwaway
# container, pgd5-timeouts, removed at the end: creating a role is an instance change, never
# done on the lab.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
c=pgd5-timeouts
trap '$docker rm -f $c >/dev/null 2>&1 || true' EXIT
start_pg $c

echo "== 1. a role for the application, and its settings"
sql $c -q <<'SQL'
create role md5_app login password 'md5-demo';
create table md5_account (id int primary key, balance numeric);
insert into md5_account values (1, 100);
grant select, update on md5_account to md5_app;
alter role md5_app set idle_in_transaction_session_timeout = '3s';
alter role md5_app set lock_timeout = '2s';
SQL
sql $c -c '\drds md5_app'

echo "== 2. the application forgets its transaction"
$docker exec -i -e PGPASSWORD=md5-demo $c psql -h 127.0.0.1 -U md5_app -d postgres -X -e 2>&1 <<'SQL' || true
show idle_in_transaction_session_timeout;
begin;
update md5_account set balance = balance + 1 where id = 1;
\! sleep 4
select balance from md5_account where id = 1;
SQL

echo "== 3. the server log"
$docker logs $c 2>&1 | grep -E 'idle-in-transaction' | sed -E 's/^[0-9-]+ [0-9:.]+ UTC \[[0-9]+\] //'

echo "== 4. the row is free again: balance unchanged"
sql $c -c "select balance from md5_account where id = 1"
