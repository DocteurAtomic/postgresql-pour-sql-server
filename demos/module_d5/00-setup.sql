-- Module D5, setup. Lab database (pachadataformation), psql:
--   docker compose exec db psql -U postgres -d pachadataformation -f /demos/module_d5/00-setup.sql
-- Creates the extension pg_stat_statements, which the lab loads at startup
-- (shared_preload_libraries), and outils.md5_session, a copy of stage.session that the
-- blocking scenes of clips D5.1 and D5.2 lock. 99-cleanup.sql drops both.
create extension if not exists pg_stat_statements;

drop table if exists outils.md5_session;
create table outils.md5_session as
select sessionid, stageid, datedebut, prix
from stage.session;
alter table outils.md5_session add primary key (sessionid);

select extname, extversion from pg_extension where extname = 'pg_stat_statements';
select count(*) as md5_sessions from outils.md5_session;
