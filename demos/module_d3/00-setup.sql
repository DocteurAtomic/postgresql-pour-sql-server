-- Module D3, setup. Lab database (pachadataformation), psql:
--   docker compose exec db psql -U postgres -d pachadataformation -f /demos/module_d3/00-setup.sql
-- The module creates no object in the lab: pg_dump, pg_basebackup, archiving and recovery
-- run in throwaway pgd3-* containers started by the .sh files, which restore their own copy
-- of pachadataformation from the dump of setup/install.sh.
select version();
