-- ci: skip (two sessions: play it after 03a-writer.sql, see scene.sh)
-- Clip 3.3, session B. Read uncommitted reads no uncommitted data; repeatable read keeps
-- the snapshot of its first statement, and refuses to update a row changed since.
begin transaction isolation level read uncommitted;
select sessionid, prix from outils.m03_session where sessionid = 40;
commit;

begin transaction isolation level repeatable read;
select sessionid, prix from outils.m03_session where sessionid = 40;
select pg_sleep(4);                       -- A commits meanwhile
select sessionid, prix from outils.m03_session where sessionid = 40;
\set ON_ERROR_STOP off
update outils.m03_session set prix = prix + 10 where sessionid = 40;
\echo SQLSTATE :LAST_ERROR_SQLSTATE
\set ON_ERROR_STOP on
rollback;

select sessionid, prix from outils.m03_session where sessionid = 40;
