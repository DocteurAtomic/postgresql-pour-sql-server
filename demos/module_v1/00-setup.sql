-- Module V1, setup. Lab database (pachadataformation), psql:
--   docker compose exec db psql -U postgres -d pachadataformation -f /demos/module_v1/00-setup.sql
-- The module needs no extension. The scripts that write (clips V1.4 to V1.6) work on
-- copies they create under outils.mv1_* and drop at the end; 99-cleanup.sql drops what an
-- interrupted run leaves behind. This script only checks that no copy is left.
select count(*) as leftover_copies
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'outils' and c.relname like 'mv1\_%';
