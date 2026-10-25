-- Module 3 exercise, starting point. Lab database (pachadataformation), psql:
--   docker compose exec db psql -U postgres -d pachadataformation -f /exercises/module_03/1-start.sql
-- Creates outils.m03_exercise, a copy of inscription.inscription with autovacuum disabled
-- (for the measure of question 2 only), and the pgstattuple extension.
-- 3-solution.sql drops both.
create extension if not exists pgstattuple;
drop table if exists outils.m03_exercise;
create table outils.m03_exercise with (autovacuum_enabled = off) as
select inscriptionid, sessionid, contactid, remise, present
from inscription.inscription;
alter table outils.m03_exercise add primary key (inscriptionid);
vacuum analyze outils.m03_exercise;
select count(*) as rows_copied from outils.m03_exercise;
