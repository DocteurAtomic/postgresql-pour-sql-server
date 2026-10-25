-- Module 5, setup. Lab database (pachadataformation), psql:
--   docker compose exec db psql -U postgres -d pachadataformation -f /demos/module_05/00-setup.sql
-- Creates outils.m05_facture, a copy of inscription.facture that autovacuum leaves alone,
-- so that clip 5.2 can show an Index Only Scan before and after VACUUM. ANALYZE only:
-- the visibility map of the copy stays empty until 02-scans.sql runs VACUUM.
-- 99-cleanup.sql drops it.
drop table if exists outils.m05_facture;
create table outils.m05_facture with (autovacuum_enabled = off) as
select * from inscription.facture;
alter table outils.m05_facture add primary key (facturecd);
create index m05_facture_datefacture on outils.m05_facture (datefacture);
analyze outils.m05_facture;

select relname, relpages, reltuples::bigint as rows, relallvisible
from pg_class
where oid = 'outils.m05_facture'::regclass;
