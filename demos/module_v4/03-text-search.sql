-- Clip V4.3: LIKE and the indexes. Lab database, psql, after 00-setup.sql (pg_trgm).
-- The database collation is en_US.utf8 (libc), not C. The clip drops what it creates.

select datcollate from pg_database where datname = current_database();

-- A plain B-tree on email serves the equality...
create index mv4_inscription_email on outils.mv4_inscription (email);
explain analyze
select inscriptionid, email
from outils.mv4_inscription
where email = 'l.joly@accuquote.example';

-- ... not a LIKE anchored at the start, under a collation other than C.
explain analyze
select inscriptionid, email
from outils.mv4_inscription
where email like 'l.jo%';

-- varchar_pattern_ops compares character by character: LIKE 'abc%' becomes a range.
create index mv4_inscription_email_pattern on outils.mv4_inscription (email varchar_pattern_ops);
explain analyze
select inscriptionid, email
from outils.mv4_inscription
where email like 'l.jo%';

-- It does not serve < or ORDER BY in the collation order: the plain index does.
explain (costs off)
select inscriptionid, email
from outils.mv4_inscription
where email > 'l.jo'
order by email
limit 5;

-- A pattern that is not anchored: no B-tree helps.
explain analyze
select inscriptionid, email
from outils.mv4_inscription
where email like '%otlehij%';

-- pg_trgm cuts the strings into trigrams; a GIN index on them serves LIKE and ILIKE.
select show_trgm('joly');
create index mv4_inscription_email_trgm on outils.mv4_inscription
    using gin (email gin_trgm_ops);
explain analyze
select inscriptionid, email
from outils.mv4_inscription
where email like '%otlehij%';
explain analyze
select inscriptionid, email
from outils.mv4_inscription
where email ilike '%OTLEHIJ%';

-- Two characters make no trigram the index can look up.
explain (costs off)
select inscriptionid, email
from outils.mv4_inscription
where email like '%ot%';

select relname, pg_size_pretty(pg_relation_size(oid)) as size
from pg_class
where relname like 'mv4_inscription_email%'
order by relname;

drop index outils.mv4_inscription_email;
drop index outils.mv4_inscription_email_pattern;
drop index outils.mv4_inscription_email_trgm;
