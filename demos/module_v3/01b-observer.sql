-- ci: skip (two sessions: play it one second after 01a-forgotten-commit.sql, see scene.sh)
-- Clip V3.1, session B: what the server sees of session A, then after its timeout.
select state, backend_xid is not null as has_xid,
       round(extract(epoch from now() - state_change)) as idle_s
from pg_stat_activity
where datname = current_database() and query like 'update outils.mv3_inscription%';
select pg_sleep(4);
select count(*) as sessions_idle_in_transaction
from pg_stat_activity
where datname = current_database() and state = 'idle in transaction';
