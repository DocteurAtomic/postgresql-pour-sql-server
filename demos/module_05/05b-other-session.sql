-- Clip 5.5: another session, psql, while 05-generic-plan.sql runs or after it.
-- A prepared statement belongs to the session that prepared it: none here.
select name, generic_plans, custom_plans from pg_prepared_statements;
