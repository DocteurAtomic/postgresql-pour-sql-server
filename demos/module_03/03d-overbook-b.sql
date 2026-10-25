-- ci: skip (two sessions: play it after 03c-overbook-a.sql, see scene.sh)
-- Clip 3.3, session B: the same enrollment as A, one second later.
-- 1. Repeatable read.
begin transaction isolation level repeatable read;
select count(*) as enrolled from outils.m03_inscription where sessionid = 41;
select pg_sleep(2);                       -- A commits meanwhile
insert into outils.m03_inscription (inscriptionid, sessionid)
select 900002, 41
where (select count(*) from outils.m03_inscription where sessionid = 41) < 12;
commit;

select pg_sleep(3);                       -- A counts, then resets

-- 2. Serializable.
begin transaction isolation level serializable;
select count(*) as enrolled from outils.m03_inscription where sessionid = 41;
select pg_sleep(2);
\set ON_ERROR_STOP off
insert into outils.m03_inscription (inscriptionid, sessionid)
select 900002, 41
where (select count(*) from outils.m03_inscription where sessionid = 41) < 12;
\echo SQLSTATE :LAST_ERROR_SQLSTATE
commit;
\set ON_ERROR_STOP on
