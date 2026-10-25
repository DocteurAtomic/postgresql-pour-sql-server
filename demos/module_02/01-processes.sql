-- Clip 2.1: the processes of the instance. Lab database, psql.
-- Every row of pg_stat_activity is an operating system process, not a thread.
select backend_type, count(*) as processes
from pg_stat_activity
group by backend_type
order by backend_type;

-- The process that serves this connection: its pid is an operating system pid.
select pg_backend_pid() as my_pid;

select pid, backend_type, datname, usename, state,
       backend_start::time(0) as started
from pg_stat_activity
where backend_type = 'client backend'
order by backend_start;

-- The private memory of this process, outside shared_buffers.
select pg_size_pretty(sum(total_bytes)) as backend_private_memory,
       count(*) as memory_contexts
from pg_backend_memory_contexts;

-- The connection limit, and the slots kept for superusers.
select name, setting, context
from pg_settings
where name in ('max_connections', 'superuser_reserved_connections',
               'reserved_connections', 'io_method', 'io_workers')
order by name;
