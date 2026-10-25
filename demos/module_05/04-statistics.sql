-- Clip 5.4: the planner statistics. Lab database, psql.
-- Creates the extended statistics outils.m05_ville_cp_region on reference.ville and
-- analyzes the table; 99-cleanup.sql drops them and analyzes the table again.

-- What ANALYZE keeps for one column: inscription.facture.relance.
select null_frac, n_distinct,
       cardinality(most_common_vals::text::smallint[]) as mcv_count,
       (most_common_vals::text::smallint[])[1:4] as first_values,
       most_common_freqs[1:4] as first_freqs,
       round((select sum(f) from unnest(most_common_freqs) as f)::numeric, 4) as mcv_total
from pg_stats
where schemaname = 'inscription' and tablename = 'facture' and attname = 'relance';

-- A frequent value: its frequency times the number of rows.
explain select facturecd from inscription.facture where relance = 0;
-- A value outside the list: what the list leaves, shared among the other distinct values.
explain select facturecd from inscription.facture where relance = 29;
select round((1 - 0.6679) / (256 - 100) * reltuples) as estimate_for_29
from pg_class where oid = 'inscription.facture'::regclass;
select count(*) as actual_for_29 from inscription.facture where relance = 29;

-- A range: the histogram, 101 bounds, 100 buckets of the same number of rows.
select cardinality(histogram_bounds::text::date[]) as bounds,
       (histogram_bounds::text::date[])[1:3] as first_bounds
from pg_stats
where schemaname = 'inscription' and tablename = 'facture' and attname = 'datefacture';

-- The join estimate of clip 5.1: 20 enrollments, 3 039 sessions, and n_distinct of
-- inscription.sessionid, negative: a fraction of the rows.
select attname, n_distinct, round(-n_distinct * 30436) as distinct_values
from pg_stats
where schemaname = 'inscription' and tablename = 'inscription' and attname = 'sessionid';
select round(20 * 3039 / round(-n_distinct * 30436)::numeric, 1) as join_estimate
from pg_stats
where schemaname = 'inscription' and tablename = 'inscription' and attname = 'sessionid';

-- The sample: 300 rows per unit of statistics target, 30 000 rows at 100.
-- reference.ville has 35 249 rows: at 200, for this session, ANALYZE reads them all
-- and the figures below no longer depend on a random sample.
show default_statistics_target;
drop statistics if exists outils.m05_ville_cp_region;  -- a replay starts without them
set default_statistics_target = 200;
analyze verbose reference.ville;
reset default_statistics_target;

-- Two correlated columns: the postal code says the region. Each one alone is well
-- estimated; together, the planner multiplies their selectivities.
explain select villeid from reference.ville where codepostal = '51300';
explain select villeid from reference.ville where coderegion = 21;
explain analyze
select v.nomville, a.adresse1
from reference.ville as v
join contact.adresse as a on a.villeid = v.villeid
where v.codepostal = '51300' and v.coderegion = 21;

-- Extended statistics on the pair: functional dependencies.
create statistics outils.m05_ville_cp_region (dependencies)
  on codepostal, coderegion from reference.ville;
set default_statistics_target = 200;
analyze reference.ville;
reset default_statistics_target;
select statistics_name, dependencies
from pg_stats_ext
where statistics_name = 'm05_ville_cp_region';

explain analyze
select v.nomville, a.adresse1
from reference.ville as v
join contact.adresse as a on a.villeid = v.villeid
where v.codepostal = '51300' and v.coderegion = 21;
