-- Module D4, cleanup. Lab database, psql. Drops what the scripts of the module may have
-- left after an interruption, and the three extensions of 00-setup.sql. The database goes
-- back to its restored state: plpgsql as its only extension, 54 indexes.
drop table if exists outils.md4_journal, outils.md4_facture, outils.md4_archive,
                     outils.md4_reset;
drop extension if exists amcheck;
drop extension if exists pg_visibility;
drop extension if exists pgstattuple;
select string_agg(extname, ', ' order by extname) as extensions from pg_extension;
select count(*) as indexes from pg_indexes
where schemaname not in ('pg_catalog', 'information_schema');
