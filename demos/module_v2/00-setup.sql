-- Module V2, setup. Lab database (pachadataformation), psql:
--   docker compose exec db psql -U postgres -d pachadataformation -f /demos/module_v2/00-setup.sql
-- Creates nothing: PL/pgSQL is installed in every database. Every object of the module is
-- created and dropped by the script that needs it, in the outils schema, with the mv2_
-- prefix; 99-cleanup.sql drops what an interrupted run leaves behind.

-- The procedural languages of the database.
select lanname, lanpltrusted
from pg_language
where lanname in ('sql', 'plpgsql')
order by lanname;

-- The port of PachaDataFormation carried no function, procedure or trigger.
select count(*) as routines
from pg_proc as p
join pg_namespace as n on n.oid = p.pronamespace
where n.nspname not in ('pg_catalog', 'information_schema');
select count(*) as triggers
from pg_trigger
where not tgisinternal;
