-- Clip V4.4: GIN, GiST and BRIN. Lab database, psql, after 00-setup.sql.
-- The clip drops what it creates, including a BRIN index on inscription.inscription.

-- GIN on jsonb: the inscriptions that need a step-free access, 3,022 rows.
explain analyze
select inscriptionid, sessionid
from outils.mv4_inscription
where options @> '{"amenagement": "pmr"}';

create index mv4_inscription_options on outils.mv4_inscription using gin (options);
explain analyze
select inscriptionid, sessionid
from outils.mv4_inscription
where options @> '{"amenagement": "pmr"}';

-- The index serves the operators of its operator class (@>, ?), not ->> and =.
explain (costs off)
select inscriptionid, sessionid
from outils.mv4_inscription
where options ->> 'amenagement' = 'pmr';

-- GIN on a text array: @> uses it, = ANY does not.
create index mv4_inscription_tags on outils.mv4_inscription using gin (tags);
explain analyze
select inscriptionid
from outils.mv4_inscription
where tags @> array['urgent'];
explain (costs off)
select inscriptionid
from outils.mv4_inscription
where 'urgent' = any (tags);

-- GiST on a range: who is in training on 12 March 2026.
create index mv4_inscription_periode on outils.mv4_inscription using gist (periode);
explain analyze
select inscriptionid, sessionid
from outils.mv4_inscription
where periode @> date '2026-03-12';

drop index outils.mv4_inscription_options;
drop index outils.mv4_inscription_tags;
drop index outils.mv4_inscription_periode;

-- BRIN keeps the minimum and maximum of each range of 128 pages. datecreation follows
-- the physical order of the table: one month of inscriptions.
explain analyze
select count(*), avg(remise)
from outils.mv4_inscription
where datecreation >= timestamp '2026-03-01' and datecreation < timestamp '2026-04-01';

create index mv4_inscription_datecreation_brin on outils.mv4_inscription
    using brin (datecreation);
explain analyze
select count(*), avg(remise)
from outils.mv4_inscription
where datecreation >= timestamp '2026-03-01' and datecreation < timestamp '2026-04-01';

-- The B-tree on the same column, for its size.
create index mv4_inscription_datecreation_btree on outils.mv4_inscription (datecreation);
select relname, pg_size_pretty(pg_relation_size(oid)) as size
from pg_class
where relname like 'mv4_inscription_datecreation%'
order by relname;
drop index outils.mv4_inscription_datecreation_btree;
drop index outils.mv4_inscription_datecreation_brin;

-- On the inscriptions of the base, datecreation is correlated (0.88), but a few rows out
-- of order widen the minimum and maximum of almost every range.
select correlation
from pg_stats
where schemaname = 'inscription' and tablename = 'inscription' and attname = 'datecreation';
create index mv4_brin_inscription on inscription.inscription using brin (datecreation);
explain analyze
select count(*)
from inscription.inscription
where datecreation >= timestamp '2019-03-01' and datecreation < timestamp '2019-04-01';
select relpages from pg_class where oid = 'inscription.inscription'::regclass;
drop index inscription.mv4_brin_inscription;
