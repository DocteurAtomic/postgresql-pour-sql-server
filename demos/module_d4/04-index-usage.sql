-- Clip D4.4: redundant indexes found by their definition, and unused indexes found by a
-- measure over a known period. Lab database, psql, after 00-setup.sql. One session; it
-- writes nothing but a temporary table, and resets no statistics.

-- 1. Redundant by definition: on the same table, a non-unique B-tree index whose key
-- columns are the leading columns of another one, neither partial nor on an expression.
select a.indrelid::regclass as table_name,
       a.indexrelid::regclass as redundant_index,
       b.indexrelid::regclass as covered_by,
       pg_size_pretty(pg_relation_size(a.indexrelid)) as size
from pg_index as a
join pg_index as b on b.indrelid = a.indrelid and b.indexrelid <> a.indexrelid
join pg_class as ca on ca.oid = a.indexrelid
join pg_class as cb on cb.oid = b.indexrelid
where ca.relam = (select oid from pg_am where amname = 'btree') and cb.relam = ca.relam
  and not a.indisunique
  and a.indpred is null and b.indpred is null and a.indexprs is null and b.indexprs is null
  and a.indnkeyatts <= b.indnkeyatts
  and (b.indkey::int2[])[0:a.indnkeyatts - 1] = (a.indkey::int2[])[0:a.indnkeyatts - 1]
  and a.indrelid::regclass::text not like 'outils.md4%'
order by 1, 2;

-- 2. The counters: idx_scan counts the scans of each index since the last reset of the
-- statistics of the database, which a restore or a copy does not carry over.
select count(*) as indexes, count(*) filter (where idx_scan = 0) as never_scanned
from pg_stat_user_indexes
where relid::regclass::text not like 'outils.md4%';
select stats_reset, pg_postmaster_start_time() as instance_started
from pg_stat_database where datname = current_database();

-- 3. A measure over a known period: a snapshot of the counters, the workload, the difference.
create temporary table md4_before as
select indexrelid, idx_scan from pg_stat_user_indexes;

-- The workload: what the application does with the invoices, a hundred times each.
do $$
declare
    d date;
    n bigint;
begin
    for d in select distinct datefacture from inscription.facture
             where datefacture >= date '2010-01-01' order by 1 limit 100 loop
        select count(*) into n from inscription.facture where datefacture = d;
        select count(*) into n from inscription.facture
        where datefacture between d and d + 6 and relance > 0;
        select count(*) into n from inscription.facture where relance = 3;
        select count(*) into n from inscription.facture
        where facturecd = (select min(facturecd) from inscription.facture where datefacture = d);
    end loop;
end
$$;
select pg_stat_force_next_flush();

select s.indexrelid::regclass as index_name, s.idx_scan - b.idx_scan as scans_in_period,
       pg_size_pretty(pg_relation_size(s.indexrelid)) as size
from pg_stat_user_indexes as s
join md4_before as b using (indexrelid)
where s.relid = 'inscription.facture'::regclass
order by scans_in_period desc, index_name;

drop table md4_before;

-- 4. nix_facture_relance4 is redundant but used: the planner prefers it, being smaller.
-- Dropped inside a transaction, the same query reads nix_facture_relance3, as many pages.
-- The DROP locks the table until the ROLLBACK: on a busy instance, a test copy is better.
begin;
drop index inscription.nix_facture_relance4;
explain (analyze, costs off, timing off, summary off)
select count(*) from inscription.facture where datefacture = date '2011-03-14';
rollback;
explain (analyze, costs off, timing off, summary off)
select count(*) from inscription.facture where datefacture = date '2011-03-14';
