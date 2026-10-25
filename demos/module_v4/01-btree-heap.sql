-- Clip V4.1: a B-tree without a clustered index. Lab database, psql, after 00-setup.sql.
-- The rows of outils.mv4_inscription are stored in the order of datecreation; the 99 rows
-- of a contact are spread over the whole table. The clip drops what it creates.

-- No index on contactid: the whole table is read.
explain analyze
select inscriptionid, sessionid, datecreation
from outils.mv4_inscription
where contactid = 1203;

-- A B-tree on contactid finds the 99 rows, then reads one table page per row.
create index mv4_inscription_contactid on outils.mv4_inscription (contactid);
explain analyze
select inscriptionid, sessionid, datecreation
from outils.mv4_inscription
where contactid = 1203;

-- Where they are: ctid is (page, position) in the heap.
select ctid, inscriptionid, datecreation
from outils.mv4_inscription
where contactid = 1203
order by ctid
limit 4;

-- CLUSTER sorts a table once, along an index. It rewrites the whole table under an
-- ACCESS EXCLUSIVE lock: shown here on a narrow copy, so as to keep the order of
-- outils.mv4_inscription for clip V4.4.
create table outils.mv4_by_contact as
select inscriptionid, contactid, sessionid, datecreation from outils.mv4_inscription;
create index mv4_by_contact_contactid on outils.mv4_by_contact (contactid);
cluster outils.mv4_by_contact using mv4_by_contact_contactid;
analyze outils.mv4_by_contact;

explain analyze
select inscriptionid, sessionid, datecreation
from outils.mv4_by_contact
where contactid = 1203;

-- The order is not kept: a new row of contact 1203 goes to the end of the table.
insert into outils.mv4_by_contact (inscriptionid, contactid, sessionid, datecreation)
values (99000001, 1203, 40, timestamp '2026-07-21 09:00')
returning ctid;
select ctid, inscriptionid
from outils.mv4_by_contact
where contactid = 1203
order by ctid desc
limit 3;
select relpages from pg_class where oid = 'outils.mv4_by_contact'::regclass;

-- INCLUDE (PostgreSQL 11): non-key columns stored in the leaf pages of the index.
-- The table was vacuumed by 00-setup.sql: every page is marked in the visibility map.
drop index outils.mv4_inscription_contactid;
create index mv4_inscription_contact_incl on outils.mv4_inscription (contactid)
    include (sessionid, datecreation);
explain analyze
select inscriptionid, sessionid, datecreation
from outils.mv4_inscription
where contactid = 1203;
-- inscriptionid is not in the index: the same query without it.
explain analyze
select sessionid, datecreation
from outils.mv4_inscription
where contactid = 1203;

drop index outils.mv4_inscription_contact_incl;
drop table outils.mv4_by_contact;
