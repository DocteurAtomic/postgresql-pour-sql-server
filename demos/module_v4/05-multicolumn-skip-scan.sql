-- Clip V4.5: multicolumn indexes and the B-tree skip scan (PostgreSQL 18). Lab database,
-- psql, after 00-setup.sql. The clip drops what it creates. The same query on
-- PostgreSQL 17: 05b-skip-scan-pg17.sh.

-- Equality on the first column, order on the second: no Sort, the index is read backward.
create index mv4_inscription_session_date on outils.mv4_inscription (sessionid, datecreation);
explain analyze
select inscriptionid, datecreation
from outils.mv4_inscription
where sessionid = 40
order by datecreation desc
limit 5;

-- A condition on the second column only: one index search per value of sessionid
-- (Index Searches), skip scan. 10,000 sessions make many searches.
explain analyze
select count(*)
from outils.mv4_inscription
where datecreation >= timestamp '2026-03-01' and datecreation < timestamp '2026-03-02';

-- Two values in the first column: two groupings to visit.
drop index outils.mv4_inscription_session_date;
create index mv4_inscription_present_date on outils.mv4_inscription (present, datecreation);
explain analyze
select count(*)
from outils.mv4_inscription
where datecreation >= timestamp '2026-03-01' and datecreation < timestamp '2026-03-02';
select relpages from pg_class where relname = 'mv4_inscription_present_date';
drop index outils.mv4_inscription_present_date;

-- inscription.facture has an index (relance, datefacture), among four redundant ones.
-- On a copy with this index only: Index Searches counts the descents from the root,
-- not the pages; the 36 pages of this small index are read almost all.
create table outils.mv4_facture as select * from inscription.facture;
alter table outils.mv4_facture add primary key (facturecd);
create index mv4_facture_relance_date on outils.mv4_facture (relance, datefacture);
vacuum analyze outils.mv4_facture;
select count(distinct relance) as relance_values from outils.mv4_facture;
explain analyze
select facturecd, relance
from outils.mv4_facture
where datefacture = date '2011-03-14';
select relpages from pg_class where relname = 'mv4_facture_relance_date';
drop table outils.mv4_facture;
