-- Module V6 exercise, setup. Lab database, psql:
--   docker compose exec db psql -U postgres -d pachadataformation -f /exercises/module_v6/1-setup.sql
-- Creates pg_trgm, unaccent and fuzzystrmatch if they are missing, and outils.mv6x_stage, a copy of the
-- 168 French course titles. 3-cleanup.sql drops what the exercise creates.
create extension if not exists pg_trgm;
create extension if not exists unaccent;
create extension if not exists fuzzystrmatch;

drop table if exists outils.mv6x_stage;
create table outils.mv6x_stage as
select stageid, titre
from stage.stagelangue
where languecd = 'FR';
alter table outils.mv6x_stage add primary key (stageid);
analyze outils.mv6x_stage;

-- The search as a visitor types it: no accent, a typo, a truncated name.
select count(*) as ilike_developpement
from outils.mv6x_stage
where titre ilike '%developpement%';
