-- Module D5 exercise, solution. Lab database, psql, while the sessions of 1-start.sh run.
-- Only the sessions of the exercise are terminated: application_name of 1-start.sh, in this
-- database. Run with no scene (in the course's CI), every query returns no row.
\pset null '-'

-- 1. The sessions of the database, what they do and what they wait for.
select pid, application_name as app, state, wait_event_type as wtype, wait_event,
       round(extract(epoch from now() - xact_start)) as xact_s, left(query, 45) as query
from pg_stat_activity
where datname = current_database() and backend_type = 'client backend'
  and pid <> pg_backend_pid()
order by xact_start nulls last;

-- 2. Who blocks whom.
select pid, application_name as app, pg_blocking_pids(pid) as blocked_by
from pg_stat_activity
where datname = current_database() and wait_event_type = 'Lock';

-- 3. The head of the chain, and how many sessions wait behind it.
with recursive waits as (
    select pid, unnest(pg_blocking_pids(pid)) as blocker
    from pg_stat_activity
    where datname = current_database() and wait_event_type = 'Lock'
), tree (head, pid) as (
    select blocker, pid from waits where blocker not in (select pid from waits)
    union
    select t.head, w.pid from tree t join waits w on w.blocker = t.pid
)
select a.pid, a.application_name as app, a.state, count(distinct t.pid) as waiting_behind,
       round(extract(epoch from now() - a.state_change)) as idle_s, left(a.query, 60) as last_query
from tree t join pg_stat_activity a on a.pid = t.head
group by a.pid, a.application_name, a.state, a.state_change, a.query;

-- 4. What it holds.
select l.locktype, l.relation::regclass as relation, l.mode, l.granted
from pg_locks l join pg_stat_activity a on a.pid = l.pid
where a.datname = current_database() and a.application_name = 'crm'
  and l.locktype in ('relation', 'transactionid')
order by l.locktype, relation;

-- 5. pg_cancel_backend on it: true, and nothing changes, there is no query to cancel.
select application_name as app, pg_cancel_backend(pid) as cancel_sent
from pg_stat_activity
where datname = current_database() and application_name = 'crm';
select pg_sleep(1);
select application_name as app, state from pg_stat_activity
where datname = current_database() and application_name = 'crm';

-- 6. pg_terminate_backend: the session goes, its transaction is rolled back, the chain ends.
select application_name as app, pg_terminate_backend(pid) as terminated
from pg_stat_activity
where datname = current_database() and application_name = 'crm'
  and state like 'idle in transaction%';
select pg_sleep(1);
select application_name as app, state, wait_event_type as wtype
from pg_stat_activity
where datname = current_database() and backend_type = 'client backend'
  and application_name in ('crm', 'export', 'dashboard', 'billing', 'nightly-batch', 'reporting')
order by app;
select count(*) filter (where column_name = 'checked') as checked_column_added
from information_schema.columns
where table_schema = 'outils' and table_name = 'md5_exercise';
