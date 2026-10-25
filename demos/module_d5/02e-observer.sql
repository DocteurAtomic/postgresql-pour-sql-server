-- ci: skip
-- Clip D5.2, session E: the DBA. Who waits for whom, then the head of the chain, what it
-- holds, and pg_terminate_backend on it. Only the sessions of the scene are touched:
-- application_name md5-*, in this database.
\pset null '-'
-- Each waiting session and the sessions that block it.
select pid, application_name as app, state, wait_event_type as wtype, wait_event,
       pg_blocking_pids(pid) as blocked_by, left(query, 35) as query
from pg_stat_activity
where datname = current_database() and application_name like 'md5-%'
  and pid <> pg_backend_pid()
order by query_start;

-- The head of each chain: a session that blocks others and waits for nobody, with the
-- number of sessions that wait behind it, directly or not.
with recursive waits as (
    select pid, unnest(pg_blocking_pids(pid)) as blocker
    from pg_stat_activity
    where datname = current_database() and wait_event_type = 'Lock'
), tree (head, pid) as (
    select blocker, pid from waits
    where blocker not in (select pid from waits)
    union
    select t.head, w.pid from tree t join waits w on w.blocker = t.pid
)
select a.pid, a.application_name as app, a.state,
       round(extract(epoch from now() - a.xact_start)::numeric, 1) as xact_s,
       round(extract(epoch from now() - a.state_change)::numeric, 1) as idle_s,
       count(distinct t.pid) as waiting_behind, left(a.query, 35) as last_query
from tree t
join pg_stat_activity a on a.pid = t.head
group by a.pid, a.application_name, a.state, a.xact_start, a.state_change, a.query;

-- What the head holds.
select l.locktype, l.relation::regclass as relation, l.transactionid as xid, l.mode, l.granted
from pg_locks l
join pg_stat_activity a on a.pid = l.pid
where a.datname = current_database() and a.application_name = 'md5-app'
  and l.locktype in ('relation', 'transactionid')
order by l.locktype, relation;

select application_name, pg_terminate_backend(pid) as terminated
from pg_stat_activity
where datname = current_database() and backend_type = 'client backend'
  and application_name = 'md5-app' and state = 'idle in transaction';
select pg_sleep(1);
select application_name as app, state, wait_event_type as wtype
from pg_stat_activity
where datname = current_database() and application_name like 'md5-%'
  and pid <> pg_backend_pid();
