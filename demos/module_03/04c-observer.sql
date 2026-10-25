-- ci: skip (three sessions: play it two seconds after 04a-holder.sql, see scene.sh)
-- Clip 3.4, session C: who waits for whom, then the same UPDATE with lock_timeout.
select pid, wait_event_type, wait_event, pg_blocking_pids(pid) as blocked_by,
       left(query, 50) as query
from pg_stat_activity
where datname = current_database() and pid <> pg_backend_pid() and state <> 'idle'
order by backend_start;

-- The locks of A and B: B waits for the transaction of A, not for a lock on the row.
select pid, locktype, transactionid, mode, granted
from pg_locks
where locktype in ('transactionid', 'tuple')
  and pid in (select pid from pg_stat_activity
              where datname = current_database() and pid <> pg_backend_pid())
order by granted desc, pid;

set lock_timeout = '2s';
\set ON_ERROR_STOP off
\timing on
update outils.m03_session set prix = prix + 20 where sessionid = 40;
\timing off
\echo SQLSTATE :LAST_ERROR_SQLSTATE
\set ON_ERROR_STOP on
