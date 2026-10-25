-- Module D3, cleanup. Lab database, psql. The module created nothing in the lab; the
-- throwaway containers of its .sh scripts remove themselves with their volumes. This
-- checks that archiving is still off on the lab and that no database of the module is left.
select current_setting('archive_mode') as archive_mode,
       (select count(*) from pg_database where datname like 'md3%') as md3_databases;
