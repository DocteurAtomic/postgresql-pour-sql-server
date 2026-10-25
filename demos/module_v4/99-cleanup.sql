-- Module V4, cleanup. Lab database, psql. Drops the generated table, the copies an
-- interrupted run leaves behind and pg_trgm: the database is as it was restored.
drop index if exists inscription.mv4_brin_inscription;
drop table if exists outils.mv4_by_contact;
drop table if exists outils.mv4_facture;
drop table if exists outils.mv4_generated;
drop table if exists outils.mv4_inscription;
drop extension if exists pg_trgm;

select count(*) as leftover_objects
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname in ('outils', 'inscription') and c.relname like 'mv4\_%';
select count(*) as pg_trgm from pg_extension where extname = 'pg_trgm';
