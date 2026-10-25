-- ci: skip (three sessions: play it with 04b-waiter.sql and 04c-observer.sql, see scene.sh)
-- Clip 3.4, session A: updates session 40 and keeps its row lock eight seconds.
begin;
update outils.m03_session set prix = 2900 where sessionid = 40;
select pg_sleep(8);
commit;
update outils.m03_session set prix = 2500 where sessionid = 40;   -- the restored price
