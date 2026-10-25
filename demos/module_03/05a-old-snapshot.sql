-- ci: skip (two sessions: play it with 05b-vacuum-blocked.sql, see scene.sh)
-- Clip 3.5, session A: a repeatable read transaction that keeps its snapshot open eight
-- seconds, like a report or a session left idle in transaction.
begin transaction isolation level repeatable read;
select count(*) from outils.m03_session;
select pg_sleep(8);
commit;
