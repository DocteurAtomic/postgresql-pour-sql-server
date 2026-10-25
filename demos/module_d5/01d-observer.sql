-- ci: skip
-- Clip D5.1, session D of the scene: the DBA. Looks at the sessions of the scene, then
-- cancels the report and terminates the forgotten transaction. Only the sessions of the
-- scene are touched: application_name md5-*, in this database.
\pset null '-'
select pid, leader_pid, backend_type, application_name as app, state,
       wait_event_type as wtype, wait_event,
       round(extract(epoch from now() - xact_start)::numeric, 1) as xact_s,
       left(query, 30) as query
from pg_stat_activity
where datname = current_database()
  and (application_name like 'md5-%' or leader_pid is not null)
  and pid <> pg_backend_pid()
order by coalesce(leader_pid, pid), leader_pid nulls first;

select pg_sleep(4);

-- pg_cancel_backend: the running query of the report stops, the session stays. Sent to
-- the forgotten transaction, it does nothing: there is no query to cancel.
select application_name, pg_cancel_backend(pid) as cancel_sent
from pg_stat_activity
where datname = current_database() and backend_type = 'client backend'
  and application_name in ('md5-report', 'md5-app');
select pg_sleep(0.5);
select application_name as app, state, left(query, 30) as query
from pg_stat_activity
where datname = current_database() and application_name like 'md5-%'
  and pid <> pg_backend_pid()
order by app;

-- pg_terminate_backend: the whole session goes, its transaction is rolled back.
select application_name, pg_terminate_backend(pid) as terminated
from pg_stat_activity
where datname = current_database() and backend_type = 'client backend'
  and application_name = 'md5-app';
select pg_sleep(0.5);
select application_name as app, state
from pg_stat_activity
where datname = current_database() and application_name like 'md5-%'
  and pid <> pg_backend_pid()
order by app;
select prix from outils.md5_session where sessionid = 40;
