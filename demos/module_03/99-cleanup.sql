-- Module 3, cleanup. Lab database, psql. Leaves the database as it was restored.
drop table if exists outils.m03_session;
drop table if exists outils.m03_inscription;
drop table if exists outils.m03_version;
drop table if exists outils.m03_facture;
drop extension if exists pgstattuple;
drop extension if exists pageinspect;

select extname from pg_extension order by extname;
select count(*) as m03_tables from pg_tables where tablename like 'm03%';
