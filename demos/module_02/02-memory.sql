-- Clip 2.2: the memory of the instance. Lab database, psql, after 00-setup.sql.
-- SET only changes this session; pg_buffercache_evict_relation empties the cache of
-- two tables of this database, to start the measure from a known state.

-- The memory settings, and when a change takes effect (context).
select name, setting, unit, context
from pg_settings
where name in ('shared_buffers', 'work_mem', 'hash_mem_multiplier',
               'maintenance_work_mem', 'effective_cache_size')
order by name;

-- work_mem is the budget of ONE sort or hash operation. 4 MB is not enough here.
explain (analyze, costs off, timing off)
select ville, email from contact.prospectus order by ville, email;

set work_mem = '64MB';
explain (analyze, costs off, timing off)
select ville, email from contact.prospectus order by ville, email;
reset work_mem;

-- shared_buffers seen from the inside: two tables, emptied from the cache first.
set max_parallel_workers_per_gather = 0;
select pg_buffercache_evict_relation('contact.prospectus') is not null as evicted,
       pg_buffercache_evict_relation('inscription.inscription') is not null as evicted;

select count(email) from contact.prospectus;              -- 69 MB, larger than shared_buffers / 4
select count(referencecommande) from inscription.inscription;  -- 10 MB

select c.relname,
       count(*) as buffers,
       pg_size_pretty(count(*) * current_setting('block_size')::bigint) as in_cache,
       pg_size_pretty(pg_relation_size(c.oid)) as table_size
from pg_buffercache as b
join pg_class as c on c.relfilenode = b.relfilenode
where b.reldatabase = (select oid from pg_database where datname = current_database())
  and b.relforknumber = 0
  and c.oid in ('contact.prospectus'::regclass, 'inscription.inscription'::regclass)
group by c.relname, c.oid
order by c.relname;
reset max_parallel_workers_per_gather;

-- The whole cache of the instance, every database included.
select buffers_used, buffers_unused, buffers_dirty
from pg_buffercache_summary();
