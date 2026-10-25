-- Module 2 exercise, solution. Lab database, psql, after 1-start.sql.
-- 2-solution.sh lists the same files from the container. Drops outils.m02_exercise at the end.

-- 1. The processes of the instance, by type, and the one that serves this session.
select backend_type, count(*) as processes
from pg_stat_activity
group by backend_type
order by backend_type;
select pg_backend_pid() as my_pid;

-- 2. The files of inscription.facture and of its indexes, relative to PGDATA.
select c.relname, c.relkind, pg_relation_filepath(c.oid) as file,
       pg_relation_size(c.oid) as main_bytes
from pg_class as c
where c.oid = 'inscription.facture'::regclass
   or c.oid in (select indexrelid from pg_index where indrelid = 'inscription.facture'::regclass)
order by c.relkind desc, c.relname;

-- 3. The table and its five indexes, every fork included.
select pg_size_pretty(pg_table_size('inscription.facture')) as table_with_fsm_vm,
       pg_size_pretty(pg_indexes_size('inscription.facture')) as indexes,
       pg_size_pretty(pg_total_relation_size('inscription.facture')) as total;

-- 4. VACUUM FULL rewrites the table into a new file: same OID, new relfilenode.
select oid, relfilenode, pg_relation_filepath(oid) as file
from pg_class where oid = 'outils.m02_exercise'::regclass;
vacuum full outils.m02_exercise;
select oid, relfilenode, pg_relation_filepath(oid) as file
from pg_class where oid = 'outils.m02_exercise'::regclass;

drop table outils.m02_exercise;
