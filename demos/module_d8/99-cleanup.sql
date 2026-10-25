-- Module D8, cleanup. Lab database, psql. The module created nothing in the lab; the
-- throwaway containers of its .sh scripts remove themselves. This checks that no database
-- and no foreign server of the module are left on the lab.
select (select count(*) from pg_database where datname like 'md8%') as md8_databases,
       (select count(*) from pg_foreign_server) as foreign_servers;
