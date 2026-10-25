-- Module V6, cleanup. Lab database, psql. Drops the tables, the function and the text search
-- configuration of the module, what an interrupted run leaves behind, and the four
-- extensions: the database is as it was restored, with plpgsql only.
drop text search configuration if exists outils.mv6_french_unaccent;
drop table if exists outils.mv6_programme;
drop table if exists outils.mv6_contact;
drop table if exists outils.mv6_stage_vecteur;
drop table if exists outils.mv6_vecteur;
drop function if exists outils.mv6_unaccent(text);   -- after the table: an index may use it
drop extension if exists pg_trgm;
drop extension if exists unaccent;
drop extension if exists fuzzystrmatch;
drop extension if exists vector;

select count(*) as leftover_objects
from pg_class c join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'outils' and c.relname like 'mv6\_%';
select string_agg(extname, ', ' order by extname) as extensions from pg_extension;
