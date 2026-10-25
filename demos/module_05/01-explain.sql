-- Clip 5.1: EXPLAIN and EXPLAIN ANALYZE. Lab database, psql.
-- Twenty enrollments, their contact and their session.

-- The estimated plan: the query is planned, not executed.
explain
select i.inscriptionid, c.nom, c.prenom, s.datedebut
from inscription.inscription as i
join contact.contact as c on c.contactid = i.contactid
join stage.session as s on s.sessionid = i.sessionid
where i.inscriptionid between 1000 and 1019;

-- The actual plan: the query runs, each node gets its time, rows, loops and buffers.
explain analyze
select i.inscriptionid, c.nom, c.prenom, s.datedebut
from inscription.inscription as i
join contact.contact as c on c.contactid = i.contactid
join stage.session as s on s.sessionid = i.sessionid
where i.inscriptionid between 1000 and 1019;

-- What a cost is made of: a sequential scan costs one seq_page_cost per page
-- and one cpu_tuple_cost per row.
select relpages, reltuples,
       current_setting('seq_page_cost') as seq_page_cost,
       current_setting('cpu_tuple_cost') as cpu_tuple_cost,
       round((relpages * current_setting('seq_page_cost')::numeric
              + reltuples::numeric * current_setting('cpu_tuple_cost')::numeric), 2) as computed_cost
from pg_class
where oid = 'stage.stage'::regclass;

explain
select stageid, categorie from stage.stage;

-- EXPLAIN ANALYZE executes the statement: an UPDATE really updates.
-- In a transaction, then ROLLBACK.
begin;
explain (analyze, costs off)
update stage.session set prix = prix + 100 where sessionid = 41;
select sessionid, prix from stage.session where sessionid = 41;
rollback;
select sessionid, prix from stage.session where sessionid = 41;
