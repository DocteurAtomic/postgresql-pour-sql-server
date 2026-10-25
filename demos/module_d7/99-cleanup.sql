-- Module D7, cleanup. Lab database, psql. The module created nothing in the lab; the
-- throwaway containers of its .sh scripts remove themselves with their volumes. This checks
-- that no database of the module is left on the lab.
select count(*) as md7_databases from pg_database where datname like 'md7%';
