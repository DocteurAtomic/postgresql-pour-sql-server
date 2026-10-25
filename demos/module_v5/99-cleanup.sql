-- Module V5, cleanup. Lab database, psql. Leaves the database as it was restored: drops
-- every object of the module, including what an interrupted run left behind.
drop table if exists outils.mv5_booking_race;
drop table if exists outils.mv5_discount;
drop table if exists outils.mv5_booking;
drop table if exists outils.mv5_session_contacts;
drop table if exists outils.mv5_stage_doc;
drop table if exists outils.mv5_evaluation;
drop domain if exists outils.mv5_percent;
drop type if exists outils.mv5_booking_status;
deallocate all;
drop extension if exists btree_gist;

select count(*) as mv5_relations_left
from pg_class
where relnamespace = 'outils'::regnamespace and relname like 'mv5\_%';
select count(*) as mv5_types_left
from pg_type
where typnamespace = 'outils'::regnamespace and typname like 'mv5\_%';
select count(*) as btree_gist_installed from pg_extension where extname = 'btree_gist';
