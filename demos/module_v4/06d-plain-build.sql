-- ci: skip (two sessions: play it with 06e-writer.sql, see scene.sh)
--   DOCKER=podman ./demos/module_03/scene.sh demos/module_v4/06d-plain-build.sql \
--       demos/module_v4/06e-writer.sql
-- Clip V4.6, session A: a plain CREATE INDEX takes a SHARE lock on the table and keeps it
-- until the end of the transaction, held five seconds more here.
begin;
create index mv4_inscription_sessionid on outils.mv4_inscription (sessionid);
select pg_sleep(5);
commit;
drop index outils.mv4_inscription_sessionid;
