-- ci: skip (four sessions: play it three seconds after 04d-reader.sql, see scene.sh)
-- Clip 3.4, session D: the queue on the table.
select pid, wait_event_type, wait_event, pg_blocking_pids(pid) as blocked_by,
       left(query, 50) as query
from pg_stat_activity
where datname = current_database() and pid <> pg_backend_pid() and state <> 'idle'
order by backend_start;

select pid, mode, granted
from pg_locks
where relation = 'outils.m03_session'::regclass
order by granted desc, pid;
