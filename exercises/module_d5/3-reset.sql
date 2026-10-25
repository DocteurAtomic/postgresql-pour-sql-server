-- Module D5 exercise, reset. Lab database, psql. Terminates what is left of the sessions of
-- 1-start.sh in this database, found by their application_name, and drops the table.
select count(pg_terminate_backend(pid)) as terminated
from pg_stat_activity
where datname = current_database() and backend_type = 'client backend'
  and application_name in ('crm', 'export', 'dashboard', 'billing', 'nightly-batch', 'reporting');
select pg_sleep(0.5);
drop table if exists outils.md5_exercise;
select count(*) as md5_exercise_tables from pg_tables where tablename = 'md5_exercise';
