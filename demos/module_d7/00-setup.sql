-- Module D7, setup. Lab database (pachadataformation), psql:
--   docker compose exec db psql -U postgres -d pachadataformation -f /demos/module_d7/00-setup.sql
-- The module creates no object in the lab: the upgrades run in throwaway pgd7-* containers
-- started by the .sh files, from the official images postgres:17 and postgres:18.
select version();
