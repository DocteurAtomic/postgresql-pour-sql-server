-- Clip D4.4: amcheck on the lab database, the nearest thing to DBCC CHECKDB. Lab
-- database, psql, after 00-setup.sql. Read only: amcheck takes an ACCESS SHARE lock and
-- reads every page it checks.
\timing on
-- 1. Every B-tree index of the database, and that each one points to every row of its
-- table (heapallindexed). An error stops the query; no row means nothing found.
select count(bt_index_check(c.oid, heapallindexed => true)::text) as btree_indexes_checked
from pg_index as i
join pg_class as c on c.oid = i.indexrelid
join pg_am as am on am.oid = c.relam
join pg_namespace as n on n.oid = c.relnamespace
where am.amname = 'btree' and n.nspname not in ('pg_catalog', 'information_schema', 'pg_toast')
  and c.relpersistence <> 't' and i.indisready and i.indisvalid;

-- 2. The pages of the two largest tables: verify_heapam returns one row per problem.
select count(*) as problems from verify_heapam('contact.prospectus');
select count(*) as problems from verify_heapam('inscription.inscription');
\timing off

-- 3. The data checksums, chosen at initdb (module D1): every page read from disk is checked.
show data_checksums;
select datname, checksum_failures, checksum_last_failure
from pg_stat_database where datname = current_database();
