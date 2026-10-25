-- Clip 3.4: row locks live in the rows. Lab database, psql, after 00-setup.sql. One session.
-- An UPDATE of every row of outils.m03_session, inside a transaction rolled back at the end:
-- pg_locks lists the locks of the table and of its index, not one lock per row.
begin;
update outils.m03_session set prix = prix where true;
select locktype, relation::regclass as relation, mode, granted
from pg_locks
where pid = pg_backend_pid() and relation is distinct from 'pg_locks'::regclass
order by locktype, relation::regclass::text;
rollback;
