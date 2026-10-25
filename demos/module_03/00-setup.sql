-- Module 3, setup. Lab database (pachadataformation), psql:
--   docker compose exec db psql -U postgres -d pachadataformation -f /demos/module_03/00-setup.sql
-- Creates the two extensions the module reads the pages with, and the demo tables, copies
-- of stage.session and inscription.inscription in the outils schema. 99-cleanup.sql drops them.
create extension if not exists pageinspect;   -- the row versions inside a page (clip 3.1)
create extension if not exists pgstattuple;   -- dead tuples and free space (clip 3.5)

-- The sessions the two-session scenes update (clips 3.2 to 3.4).
drop table if exists outils.m03_session;
create table outils.m03_session as
select sessionid, stageid, datedebut, prix, statut
from stage.session;
alter table outils.m03_session add primary key (sessionid);

-- The enrollments of the serializable scene (clip 3.3).
drop table if exists outils.m03_inscription;
create table outils.m03_inscription as
select inscriptionid, sessionid, contactid
from inscription.inscription;
alter table outils.m03_inscription add primary key (inscriptionid);
create index on outils.m03_inscription (sessionid);
vacuum analyze outils.m03_session, outils.m03_inscription;

select extname, extversion
from pg_extension
where extname in ('pageinspect', 'pgstattuple')
order by extname;

select relname, reltuples::bigint as rows
from pg_class
where oid in ('outils.m03_session'::regclass, 'outils.m03_inscription'::regclass)
order by relname;
