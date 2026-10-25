-- ci: skip (two sessions: play it with 03b-repeatable-read.sql, see scene.sh)
-- Clip 3.3, session A: updates session 40 and commits after three seconds.
-- Start session B (03b-repeatable-read.sql) one second after this one.
update outils.m03_session set prix = 2500 where sessionid = 40;   -- the restored price

begin;
update outils.m03_session set prix = 2900 where sessionid = 40;
select pg_sleep(3);
commit;
