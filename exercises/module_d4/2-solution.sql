-- Exercise D4, solution. Lab database, psql, in one session (the snapshot is a temporary
-- table). Reads the catalog and the counters, runs 1-workload.sql between two snapshots,
-- and drops what it created. Resets no statistics.
--   docker compose exec db psql -U postgres -d pachadataformation -f /exercises/module_d4/2-solution.sql

-- 1. Redundant indexes, by definition.
select a.indrelid::regclass as table_name, a.indexrelid::regclass as redundant_index,
       b.indexrelid::regclass as covered_by
from pg_index as a
join pg_index as b on b.indrelid = a.indrelid and b.indexrelid <> a.indexrelid
join pg_class as ca on ca.oid = a.indexrelid
join pg_class as cb on cb.oid = b.indexrelid
where ca.relam = (select oid from pg_am where amname = 'btree') and cb.relam = ca.relam
  and not a.indisunique
  and a.indpred is null and b.indpred is null and a.indexprs is null and b.indexprs is null
  and a.indnkeyatts <= b.indnkeyatts
  and (b.indkey::int2[])[0:a.indnkeyatts - 1] = (a.indkey::int2[])[0:a.indnkeyatts - 1]
order by 1, 2;

-- 2. What the counters say before any measure, and since when they count.
select count(*) as indexes, count(*) filter (where idx_scan = 0) as never_scanned
from pg_stat_user_indexes;
select stats_reset from pg_stat_database where datname = current_database();

-- 3. A snapshot, the workload, the difference.
create temporary table snapshot as select indexrelid, idx_scan from pg_stat_user_indexes;
\ir 1-workload.sql
select pg_stat_force_next_flush();

-- 4. The indexes the workload did not use, with what each one enforces.
select s.indexrelid::regclass as index_name, s.relid::regclass as table_name,
       s.idx_scan - b.idx_scan as scans,
       case when i.indisprimary then 'primary key' when i.indisunique then 'unique'
            else '' end as enforces,
       pg_size_pretty(pg_relation_size(s.indexrelid)) as size
from pg_stat_user_indexes as s
join snapshot as b using (indexrelid)
join pg_index as i on i.indexrelid = s.indexrelid
where s.idx_scan - b.idx_scan = 0
  and s.relid in ('contact.contact'::regclass, 'contact.adresse'::regclass,
                  'inscription.inscription'::regclass, 'inscription.facture'::regclass,
                  'stage.session'::regclass, 'reference.ville'::regclass)
order by s.relid::regclass::text, s.indexrelid::regclass::text;

-- 5. The unused indexes that serve a foreign key: their first column is the first column of
-- a foreign key of the table. Deleting a row of the referenced table looks them up.
select s.indexrelid::regclass as index_name, c.conname as foreign_key,
       c.confrelid::regclass as references
from pg_stat_user_indexes as s
join snapshot as b using (indexrelid)
join pg_index as i on i.indexrelid = s.indexrelid
join pg_constraint as c on c.conrelid = i.indrelid and c.contype = 'f'
                       and c.conkey[1] = i.indkey[0]
where s.idx_scan - b.idx_scan = 0 and not i.indisunique
order by 1;

-- The indexes the workload used, on the same tables.
select s.indexrelid::regclass as index_name, s.idx_scan - b.idx_scan as scans
from pg_stat_user_indexes as s
join snapshot as b using (indexrelid)
where s.idx_scan - b.idx_scan > 0
order by scans desc, s.indexrelid::regclass::text;

drop table snapshot;
