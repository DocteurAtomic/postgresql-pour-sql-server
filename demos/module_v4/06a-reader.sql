-- ci: skip (three sessions: play it with 06b-build.sql and 06c-writer.sql, see scene.sh)
--   DOCKER=podman ./demos/module_03/scene.sh demos/module_v4/06a-reader.sql \
--       demos/module_v4/06b-build.sql demos/module_v4/06c-writer.sql
-- Clip V4.6, session A: a transaction that keeps a snapshot eight seconds, a report or
-- a session left idle in transaction.
begin transaction isolation level repeatable read;
select count(*) from outils.mv4_inscription where inscriptionid <= 10;
select pg_sleep(8);
commit;
