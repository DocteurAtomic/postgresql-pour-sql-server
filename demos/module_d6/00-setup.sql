-- Module D6, setup. Lab database (pachadataformation), psql:
--   docker compose exec db psql -U postgres -d pachadataformation -f /demos/module_d6/00-setup.sql
-- The module creates no object in the lab: replication needs two instances or more, so
-- primaries and standbys run in throwaway pgd6-* containers, on their own network pgd6-net,
-- started and removed by the .sh files. The primary restores its own copy of
-- pachadataformation from the dump of setup/install.sh.
select version();
