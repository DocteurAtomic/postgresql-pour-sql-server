#!/usr/bin/env bash
# Clip D5.4: pg_stat_statements seen from the instance: one view for every database, the
# queryid of PostgreSQL 18 that groups tables by name, the entries evicted beyond
# pg_stat_statements.max, and what is left after a clean shutdown, an immediate one and a
# killed server. Runs on the host (DOCKER=podman for Podman), in a throwaway container,
# pgd5-statements, started with pg_stat_statements.max = 100 (its minimum); removed at the
# end. The lab is not touched.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
c=pgd5-statements
trap '$docker rm -f $c >/dev/null 2>&1 || true' EXIT
$docker run -d --name $c -e POSTGRES_PASSWORD=course $image \
    postgres -c shared_preload_libraries=pg_stat_statements -c pg_stat_statements.max=100 >/dev/null
wait_ready $c
count="select count(*) as entries, sum(calls) as calls,
              (select dealloc from pg_stat_statements_info) as dealloc
       from pg_stat_statements"

echo "== 1. the extension created in one database, the statements of all of them"
sql $c -q -c "create extension pg_stat_statements"
for d in app1 app2; do
    sql $c -q -c "create database $d"
    sql $c -q -d $d -c "create table invoice (id int primary key, amount numeric)"
done
sql $c -q -c "select pg_stat_statements_reset()" > /dev/null
for d in app1 app2; do
    for i in 1 2 3; do sql $c -q -d $d -c "select amount from invoice where id = $i" > /dev/null; done
done
sql $c -c "select d.datname, s.queryid, s.calls, s.query
           from pg_stat_statements s join pg_database d on d.oid = s.dbid
           where s.query like 'select amount%' order by d.datname"

echo "== 2. one schema per client: two tables named invoice, one entry"
sql $c -q -d app1 <<'SQL' > /dev/null
create schema client_a;
create schema client_b;
create table client_a.invoice (id int primary key, amount numeric);
create table client_b.invoice (id int primary key, total numeric, label text);
select count(*) from client_a.invoice where id = 1;
select count(*) from client_b.invoice where id = 2;
select count(*) from client_b.invoice where id = 3;
SQL
sql $c -c "select queryid, calls, query from pg_stat_statements
           where query like 'select%client_%invoice%'"

echo "== 3. 150 different statements for 100 entries"
sql $c -q -d app2 -c "do \$\$ begin for i in 1..150 loop
    execute format('create table t%s (id int)', i); end loop; end \$\$"
for i in $(seq 1 150); do echo "select count(*) from t$i;"; done | sql $c -q -d app2 > /dev/null
sql $c -c "$count"
sql $c -c "select count(*) as invoice_entries_left from pg_stat_statements
           where query like '%invoice%'"

echo "== 4. clean shutdown (pg_ctl stop -m fast), restart"
stop_pg $c fast
start_again $c
sql $c -c "$count"

echo "== 5. immediate shutdown (pg_ctl stop -m immediate), restart"
stop_pg $c immediate
start_again $c
sql $c -c "$count"
sql $c -c "select xact_commit, deadlocks from pg_stat_database where datname = 'postgres'"

echo "== 6. the server killed (SIGKILL), restart"
$docker kill -s KILL $c > /dev/null
$docker wait $c > /dev/null || true
start_again $c
sql $c -c "$count"
