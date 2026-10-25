-- Module 5, cleanup. Lab database, psql. Leaves the database as it was restored.
drop table if exists outils.m05_facture;
drop statistics if exists outils.m05_ville_cp_region;  -- the extended statistics of 04
analyze reference.ville;                                -- statistics without them again
deallocate all;

select count(*) as m05_tables from pg_tables where tablename like 'm05%';
select count(*) as m05_statistics from pg_statistic_ext where stxname like 'm05%';
