-- Module D1, setup. Lab database (pachadataformation), psql:
--   docker compose exec db psql -U postgres -d pachadataformation -f /demos/module_d1/00-setup.sql
-- The module creates no object in the database: the scripts that change the instance run
-- in throwaway containers (the .sh files) and are marked "ci: skip".
select version();
