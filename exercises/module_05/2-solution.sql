-- Exercise of module 5, solution. Lab database (pachadataformation), psql.
-- Creates nothing.

-- 1 and 2. The estimated plan, then the actual plan: compare rows= in both.
explain
select st.stageid, st.categorie, count(*) as enrollments
from inscription.inscription as i
join stage.session as s on s.sessionid = i.sessionid
join stage.stage as st on st.stageid = s.stageid
group by st.stageid, st.categorie;

explain analyze
select st.stageid, st.categorie, count(*) as enrollments
from inscription.inscription as i
join stage.session as s on s.sessionid = i.sessionid
join stage.stage as st on st.stageid = s.stageid
group by st.stageid, st.categorie;

-- 3. Why the join of inscription and session is underestimated.
select attname, n_distinct, round(-n_distinct * 30436) as distinct_values
from pg_stats
where schemaname = 'inscription' and tablename = 'inscription' and attname = 'sessionid';
-- The planner divides the product of the two row counts by the larger number of
-- distinct values.
select round(30436 * 3039 / round(-n_distinct * 30436)) as join_estimate
from pg_stats
where schemaname = 'inscription' and tablename = 'inscription' and attname = 'sessionid';

select count(*) as enrollments,
       count(*) filter (where not exists (
         select 1 from stage.session as s where s.sessionid = i.sessionid)) as without_session
from inscription.inscription as i;

select count(distinct i.sessionid) as sessions_referenced,
       count(distinct i.sessionid) filter (where exists (
         select 1 from stage.session as s where s.sessionid = i.sessionid)) as sessions_found
from inscription.inscription as i;

select exists (select 1 from stage.session as s where s.sessionid = i.sessionid) as session_found,
       count(distinct i.sessionid) as sessions,
       count(*) as enrollments,
       round(count(*)::numeric / count(distinct i.sessionid), 2) as per_session
from inscription.inscription as i
group by 1
order by 1;
