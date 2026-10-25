-- Module V7, setup. Lab database (pachadataformation), psql:
--   docker compose exec db psql -U postgres -d pachadataformation -f /demos/module_v7/00-setup.sql
-- Creates the extension pg_stat_statements, which the lab loads at startup
-- (shared_preload_libraries), and the function of clip V7.5. 99-cleanup.sql drops both.
create extension if not exists pg_stat_statements;

-- Clip V7.5: a query that an application only reaches through a function.
create or replace function outils.mv7_enrolled(p_relance smallint) returns bigint
language plpgsql stable as $$
declare
    n bigint;
begin
    select count(*) into n
    from inscription.facture f
    join inscription.inscriptionfacture fi on fi.facturecd = f.facturecd
    join inscription.inscription i on i.inscriptionid = fi.inscriptionid
    where f.relance = p_relance;
    return n;
end;
$$;

select extname, extversion from pg_extension where extname = 'pg_stat_statements';
show shared_preload_libraries;
