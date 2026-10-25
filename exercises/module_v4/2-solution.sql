-- Module V4 exercise, solution. Lab database, psql, after demos/module_v4/00-setup.sql.
--   docker compose exec db psql -U postgres -d pachadataformation -f /exercises/module_v4/2-solution.sql
-- Creates one index per query, shows the new plan, then drops the three indexes.

-- 1. An index on the expression the query uses, then ANALYZE for its statistics.
create index mv4_ex_lower_email on outils.mv4_inscription (lower(email));
analyze outils.mv4_inscription;
explain analyze
select inscriptionid, sessionid, datecreation
from outils.mv4_inscription
where lower(email) = lower('A.DaSilva@Tinachan.example');

-- 2. A partial index: only the 14,157 cancelled rows, read backward for the ORDER BY.
create index mv4_ex_cancelled on outils.mv4_inscription (dateannulation)
    where dateannulation is not null;
explain analyze
select inscriptionid, contactid, dateannulation
from outils.mv4_inscription
where dateannulation is not null
order by dateannulation desc
limit 10;

-- 3. datecreation follows the physical order of the table: a BRIN index of a few pages.
create index mv4_ex_datecreation_brin on outils.mv4_inscription using brin (datecreation);
explain analyze
select options ->> 'financement' as financement, count(*) as inscriptions
from outils.mv4_inscription
where datecreation >= timestamp '2025-12-01' and datecreation < timestamp '2025-12-08'
group by 1
order by 1;

select relname, pg_size_pretty(pg_relation_size(oid)) as size
from pg_class
where relname like 'mv4\_ex\_%'
order by relname;

drop index outils.mv4_ex_lower_email;
drop index outils.mv4_ex_cancelled;
drop index outils.mv4_ex_datecreation_brin;
