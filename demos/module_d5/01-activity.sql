-- Clip D5.1: what pg_stat_activity lists. Lab database, psql, read only.
-- One row per server process: the client sessions, and the background processes of the
-- instance, which have no database and no user.
select backend_type, count(*) as processes,
       count(datname) as with_database
from pg_stat_activity
group by backend_type
order by processes desc, backend_type;

-- The row of this session: who, from where, since when, and what it is running.
select pid, usename, datname, application_name, client_addr, state,
       backend_start, xact_start, query_start, state_change,
       wait_event_type, wait_event, left(query, 40) as query
from pg_stat_activity
where pid = pg_backend_pid()
\gx
