-- ci: skip (three sessions: play it two seconds after 06a-reader.sql, see scene.sh)
-- Clip V4.6, session C: an INSERT during the build does not wait; then, three seconds
-- later, what B is doing and whom it waits for.
\timing on
insert into outils.mv4_inscription (inscriptionid, sessionid, contactid, datecreation)
values (99000001, 40, 1203, timestamp '2026-07-21 09:00');
\timing off
select pg_sleep(3);
select phase, blocks_done, blocks_total, current_locker_pid
from pg_stat_progress_create_index;
select pid, wait_event_type, wait_event, pg_blocking_pids(pid) as blocked_by,
       left(query, 45) as query
from pg_stat_activity
where datname = current_database() and pid <> pg_backend_pid() and state <> 'idle'
order by backend_start;
select pg_sleep(4);
delete from outils.mv4_inscription where inscriptionid = 99000001;
drop index outils.mv4_inscription_sessionid;
