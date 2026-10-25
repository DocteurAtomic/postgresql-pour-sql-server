-- Module D8, setup. Lab database (pachadataformation), psql:
--   docker compose exec db psql -U postgres -d pachadataformation -f /demos/module_d8/00-setup.sql
-- The module creates no object in the lab: the migrations run in throwaway pgd8-* containers
-- started by the .sh files, from the SQL Server source described in lib.sh. On the lab, the
-- module only reads (03-portage-traces.sql, 06-identities.sql).
select version();
