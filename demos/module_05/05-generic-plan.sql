-- Clip 5.5: custom plans and the generic plan. Lab database, psql, one session.
-- The prepared statement lives in this session only; the script deallocates it.
-- inscription.facture.relance: 6 533 invoices at 0, a few dozen for each other value.
-- EXPLAIN EXECUTE counts as an execution of the prepared statement.

-- Five executions with a rare value: five custom plans.
prepare unpaid(smallint) as
select count(*) as invoices, sum(montantttc) as amount
from inscription.facture where relance = $1;
execute unpaid(29);
execute unpaid(29);
execute unpaid(29);
execute unpaid(29);
execute unpaid(29);
select name, generic_plans, custom_plans from pg_prepared_statements;

-- The sixth: the generic plan is weighed against the average of the custom plans,
-- and refused. A custom plan shows the value, 29.
explain execute unpaid(29);

-- The seventh, with the value 0: a custom plan built for 6 533 rows.
explain analyze execute unpaid(0);
select name, generic_plans, custom_plans from pg_prepared_statements;

-- The eighth, same value: the average now includes the expensive execution,
-- the generic plan wins. It shows $1, and expects 65 rows whatever the value.
explain analyze execute unpaid(0);
select name, generic_plans, custom_plans from pg_prepared_statements;
deallocate unpaid;

-- plan_cache_mode forces one or the other, for this session.
set plan_cache_mode = force_generic_plan;
prepare unpaid(smallint) as
select count(*) as invoices, sum(montantttc) as amount
from inscription.facture where relance = $1;
explain execute unpaid(29);
select name, generic_plans, custom_plans from pg_prepared_statements;
deallocate unpaid;
reset plan_cache_mode;

-- The generic plan of a query, without preparing it (PostgreSQL 16 and later).
explain (generic_plan)
select count(*) as invoices, sum(montantttc) as amount
from inscription.facture where relance = $1;
