-- Module V6 exercise, cleanup. Lab database, psql. Drops what 1-setup.sql and
-- 2-solution.sql created, extensions included: the database is as it was restored.
drop function if exists outils.mv6x_search(text, integer);
drop table if exists outils.mv6x_stage;
drop function if exists outils.mv6x_normalize(text);
drop extension if exists pg_trgm;
drop extension if exists unaccent;
drop extension if exists fuzzystrmatch;
select count(*) as leftover_objects
from pg_class c join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'outils' and c.relname like 'mv6x\_%';
