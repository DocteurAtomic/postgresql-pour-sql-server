-- Module V3 exercise, cleanup. Lab database, psql. Drops what 1-setup.sql and 2-worker.sql
-- create; the database is then as it was restored.
drop procedure if exists outils.mv3_invoice_worker(text, int, boolean);
drop table if exists outils.mv3_invoice_log;
drop table if exists outils.mv3_invoice_queue;
select count(*) as leftover_objects
from pg_class c join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'outils' and c.relname like 'mv3\_invoice%';
