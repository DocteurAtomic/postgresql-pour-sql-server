-- Module V7 exercise, solution. Lab database, psql, one session (the prepared statement and
-- the settings belong to it). Times vary from run to run; counts do not.
--   docker compose exec db psql -U postgres -d pachadataformation -f /exercises/module_v7/2-solution.sql

-- Question 1: six executions with a rare value.
prepare enrolled_by_reminder(smallint) as
select count(*) as enrollments, count(distinct i.contactid) as contacts
from inscription.facture f
join inscription.inscriptionfacture fi on fi.facturecd = f.facturecd
join inscription.inscription i on i.inscriptionid = fi.inscriptionid
where f.relance = $1;
\o /dev/null
execute enrolled_by_reminder(29);
execute enrolled_by_reminder(29);
execute enrolled_by_reminder(29);
execute enrolled_by_reminder(29);
execute enrolled_by_reminder(29);
execute enrolled_by_reminder(29);
\o
select name, generic_plans, custom_plans from pg_prepared_statements;

-- Question 2: the frequent value, until the generic plan comes ($1 in the plan).
explain (costs off) execute enrolled_by_reminder(0);
explain (costs off) execute enrolled_by_reminder(0);
explain (costs off) execute enrolled_by_reminder(0);
select name, generic_plans, custom_plans from pg_prepared_statements;

-- Question 3: the two plans for 0, side by side.
set plan_cache_mode = force_custom_plan;
explain (analyze, timing off, summary off) execute enrolled_by_reminder(0);
set plan_cache_mode = force_generic_plan;
explain (analyze, timing off, summary off) execute enrolled_by_reminder(0);

-- Question 4: 200 executions in each mode, measured by pg_stat_statements.
set pg_stat_statements.track_planning = on;
set plan_cache_mode = force_custom_plan;
select pg_stat_statements_reset(0, (select oid from pg_database where datname = current_database()), 0)
       is not null as reset;
\o /dev/null
select 'execute enrolled_by_reminder(0)' from generate_series(1, 200) \gexec
\o
select 'custom' as mode, calls, plans, round(total_plan_time::numeric, 1) as plan_ms,
       round(total_exec_time::numeric, 1) as exec_ms, round(mean_exec_time::numeric, 2) as mean_ms
from pg_stat_statements
where dbid = (select oid from pg_database where datname = current_database())
  and query like 'prepare enrolled_by_reminder%';
set plan_cache_mode = force_generic_plan;
select pg_stat_statements_reset(0, (select oid from pg_database where datname = current_database()), 0)
       is not null as reset;
\o /dev/null
select 'execute enrolled_by_reminder(0)' from generate_series(1, 200) \gexec
\o
select 'generic' as mode, calls, plans, round(total_plan_time::numeric, 1) as plan_ms,
       round(total_exec_time::numeric, 1) as exec_ms, round(mean_exec_time::numeric, 2) as mean_ms
from pg_stat_statements
where dbid = (select oid from pg_database where datname = current_database())
  and query like 'prepare enrolled_by_reminder%';

reset plan_cache_mode;
reset pg_stat_statements.track_planning;
deallocate enrolled_by_reminder;
