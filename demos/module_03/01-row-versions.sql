-- Clip 3.1: row versions. Lab database, psql, after 00-setup.sql. One session.
-- A three-row table, so that the page fits on the screen. Your transaction ids will differ.
drop table if exists outils.m03_version;
create table outils.m03_version as
select sessionid, datedebut, prix
from stage.session
where sessionid in (40, 41, 42);

-- System columns: the physical address of the row (ctid), the transaction that created
-- this version (xmin), the one that deleted or locked it (xmax, 0 if none).
select ctid, xmin, xmax, sessionid, prix
from outils.m03_version
order by sessionid;

-- An UPDATE writes a new version of the row, with a new ctid.
begin;
select pg_current_xact_id() as update_xid \gset
update outils.m03_version set prix = prix + 100 where sessionid = 41;
select ctid, xmin, xmax, sessionid, prix
from outils.m03_version
order by sessionid;
commit;

-- The page still holds the old version: its xmax is the transaction of the UPDATE,
-- its t_ctid points to the new version.
select lp, t_xmin, t_xmax, t_ctid
from heap_page_items(get_raw_page('outils.m03_version', 0));

-- A ROLLBACK undoes nothing in the table: the new version stays in the page, and the
-- status of its transaction in pg_xact says it does not count.
begin;
select pg_current_xact_id() as rollback_xid \gset
update outils.m03_version set prix = 0 where sessionid = 42;
rollback;

select ctid, xmin, xmax, sessionid, prix
from outils.m03_version
order by sessionid;

select lp, t_xmin, t_xmax, t_ctid
from heap_page_items(get_raw_page('outils.m03_version', 0));

select pg_xact_status(:'update_xid') as update_status,
       pg_xact_status(:'rollback_xid') as rollback_status;

drop table outils.m03_version;
