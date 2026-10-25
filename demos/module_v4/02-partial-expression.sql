-- Clip V4.2: partial indexes and expression indexes. Lab database, psql, after
-- 00-setup.sql. One statement fails on purpose: ON_ERROR_STOP is off around it.
-- The clip drops what it creates.

-- The cancelled inscriptions of June and July 2026: 286 rows out of three million.
explain analyze
select inscriptionid, contactid, dateannulation
from outils.mv4_inscription
where dateannulation >= date '2026-06-01';

-- A partial index holds only the rows of its WHERE clause; a full one holds them all.
create index mv4_inscription_dateannulation_full on outils.mv4_inscription (dateannulation);
create index mv4_inscription_cancelled on outils.mv4_inscription (dateannulation)
    where dateannulation is not null;
select relname, pg_size_pretty(pg_relation_size(oid)) as size
from pg_class
where relname in ('mv4_inscription_dateannulation_full', 'mv4_inscription_cancelled');
drop index outils.mv4_inscription_dateannulation_full;

-- The planner proves that dateannulation >= ... implies dateannulation is not null.
explain analyze
select inscriptionid, contactid, dateannulation
from outils.mv4_inscription
where dateannulation >= date '2026-06-01';

-- A partial index on a boolean: the waiting list of a session.
create index mv4_inscription_waiting on outils.mv4_inscription (sessionid)
    where listeattente;
explain analyze
select contactid, datecreation
from outils.mv4_inscription
where sessionid = 40 and listeattente;

-- With a parameter in place of true, the generic plan cannot use it.
explain (generic_plan)
select contactid, datecreation
from outils.mv4_inscription
where sessionid = $1 and listeattente = $2;

-- A prepared statement keeps custom plans while the generic plan costs more.
prepare waiting_list(integer, boolean) as
select contactid, datecreation
from outils.mv4_inscription
where sessionid = $1 and listeattente = $2;
execute waiting_list(40, true) \g /dev/null
execute waiting_list(40, true) \g /dev/null
execute waiting_list(40, true) \g /dev/null
execute waiting_list(40, true) \g /dev/null
execute waiting_list(40, true) \g /dev/null
execute waiting_list(40, true) \g /dev/null
explain (costs off) execute waiting_list(40, true);
select name, generic_plans, custom_plans from pg_prepared_statements;
deallocate waiting_list;

-- An expression: the address typed with capitals. Without an index, the estimate is a
-- default selectivity of 0.5 %.
explain analyze
select inscriptionid, sessionid
from outils.mv4_inscription
where lower(email) = lower('L.Joly@Accuquote.example');

create index mv4_inscription_lower_email on outils.mv4_inscription (lower(email));
-- ANALYZE collects statistics on the indexed expression, under the name of the index.
analyze outils.mv4_inscription;
select tablename, attname, n_distinct
from pg_stats
where tablename = 'mv4_inscription_lower_email';

explain analyze
select inscriptionid, sessionid
from outils.mv4_inscription
where lower(email) = lower('L.Joly@Accuquote.example');

-- The column alone does not match the expression.
explain (costs off)
select inscriptionid, sessionid
from outils.mv4_inscription
where email = 'l.joly@accuquote.example';

-- The functions of an index must be IMMUTABLE: to_char is only STABLE.
select distinct proname, provolatile from pg_proc where proname in ('lower', 'to_char') order by 1, 2;
\set ON_ERROR_STOP off
create index mv4_inscription_month on outils.mv4_inscription (to_char(datecreation, 'YYYY-MM'));
\set ON_ERROR_STOP on

-- The SQL Server way, an indexed computed column: a virtual generated column (18) cannot
-- be indexed; a stored one can, at the cost of its storage.
create table outils.mv4_generated (
    email varchar(150),
    email_lower text generated always as (lower(email)) virtual
);
\set ON_ERROR_STOP off
create index mv4_generated_email_lower on outils.mv4_generated (email_lower);
\set ON_ERROR_STOP on
drop table outils.mv4_generated;

drop index outils.mv4_inscription_cancelled;
drop index outils.mv4_inscription_waiting;
drop index outils.mv4_inscription_lower_email;
