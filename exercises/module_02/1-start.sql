-- Module 2 exercise, starting point. Lab database (pachadataformation), psql:
--   docker compose exec db psql -U postgres -d pachadataformation -f /exercises/module_02/1-start.sql
-- Creates outils.m02_exercise, a copy of inscription.facture, for question 4.
-- 2-solution.sql drops it.
drop table if exists outils.m02_exercise;
create table outils.m02_exercise as select * from inscription.facture;
select count(*) as rows_copied from outils.m02_exercise;
