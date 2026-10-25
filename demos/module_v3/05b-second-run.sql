-- ci: skip (two sessions: play it one second after 05a-invoicing.sql, see scene.sh)
-- Clip V3.5, session B: a second run of the same invoicing. It tries without waiting, then
-- waits with lock_timeout, then waits until A commits.
set application_name = 'invoicing B';
select a.application_name, l.classid, l.objid, l.mode, l.granted
from pg_locks l join pg_stat_activity a on a.pid = l.pid
where l.locktype = 'advisory';
begin;
select pg_try_advisory_xact_lock(1, 41) as got_it;
rollback;
\set ON_ERROR_STOP off
set lock_timeout = '1s';
begin;
select pg_advisory_xact_lock(1, 41);
\echo SQLSTATE :SQLSTATE
rollback;
reset lock_timeout;
\set ON_ERROR_STOP on
\timing on
begin;
select pg_advisory_xact_lock(1, 41);
commit;
\timing off
