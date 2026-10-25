-- Module V4 exercise, starting point. Lab database, psql, after
-- demos/module_v4/00-setup.sql, which generates outils.mv4_inscription (three million rows).
--   docker compose exec db psql -U postgres -d pachadataformation -f /exercises/module_v4/1-slow-queries.sql
-- Three queries of the training center, each with its plan. Note for each one the node
-- that reads the table, the Execution Time and the Buffers; then write the index that
-- makes it fast, and measure again.

-- 1. The inscriptions of a trainee who typed his address with capitals.
explain analyze
select inscriptionid, sessionid, datecreation
from outils.mv4_inscription
where lower(email) = lower('A.DaSilva@Tinachan.example');

-- 2. The ten latest cancellations.
explain analyze
select inscriptionid, contactid, dateannulation
from outils.mv4_inscription
where dateannulation is not null
order by dateannulation desc
limit 10;

-- 3. The inscriptions of the first week of December 2025, by kind of funding.
explain analyze
select options ->> 'financement' as financement, count(*) as inscriptions
from outils.mv4_inscription
where datecreation >= timestamp '2025-12-01' and datecreation < timestamp '2025-12-08'
group by 1
order by 1;
