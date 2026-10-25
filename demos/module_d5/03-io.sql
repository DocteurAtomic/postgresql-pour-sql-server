-- ci: skip (read by 03-cumulative-stats.sh in the container pgd5-stats)
-- Clip D5.3: pg_stat_io (PostgreSQL 16), the reads of the client sessions on tables and
-- indexes, and their time, which stays at zero while track_io_timing is off.
select backend_type, object, context, reads, (read_bytes / 8192)::bigint as pages_read,
       round(read_time::numeric, 1) as read_ms, hits, evictions, stats_reset::time(0)
from pg_stat_io
where backend_type = 'client backend' and object = 'relation'
  and (reads > 0 or hits > 0)
order by context;
