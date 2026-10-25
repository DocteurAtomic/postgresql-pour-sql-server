-- ci: skip (two sessions: play it with 05b-second-run.sql, see scene.sh)
-- Clip V3.5, session A: the invoicing of session 41 takes the advisory lock (1, 41) for the
-- length of its transaction, and works five seconds.
set application_name = 'invoicing A';
begin;
select pg_advisory_xact_lock(1, 41);
select pg_sleep(5);
commit;
