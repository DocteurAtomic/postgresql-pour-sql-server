-- Clip 4.3: collations. Lab database, psql, after 00-setup.sql (citext).
-- Two statements fail on purpose: ON_ERROR_STOP is off around them.

-- The collation of the database: libc, en_US.utf8, deterministic.
select datname, datlocprovider, datcollate
from pg_database
where datname = current_database();

-- A deterministic collation compares the characters: case and accents count.
select 'SQL' = 'sql' as same_case_insensitive;
select count(*) filter (where prenom = 'élise') as lower_case,
       count(*) filter (where prenom = 'Élise') as exact,
       count(*) filter (where prenom ilike 'élise') as with_ilike,
       count(*) filter (where lower(prenom) = 'élise') as with_lower
from contact.contact;

-- The b-tree index on nom serves the equality, not ILIKE (plans/pgsql-04-*.pgplan).
explain (costs off) select contactid from contact.contact where nom = 'Dupont';
explain (costs off) select contactid from contact.contact where nom ilike 'dupont';

-- ICU collations: case-insensitive (level 2), then case- and accent-insensitive (level 1).
create collation outils.m04_ci (provider = icu, locale = 'und-u-ks-level2', deterministic = false);
create collation outils.m04_ci_ai (provider = icu, locale = 'und-u-ks-level1', deterministic = false);
select 'SQL' = 'sql' collate outils.m04_ci as ci,
       'Élise' = 'élise' collate outils.m04_ci as ci_accent_kept,
       'Élise' = 'elise' collate outils.m04_ci as ci_accent_differs,
       'Élise' = 'elise' collate outils.m04_ci_ai as ci_ai;

-- A copy of the first names, with the column in the case- and accent-insensitive collation.
create table outils.m04_contact as
select contactid, prenom::varchar(50) collate outils.m04_ci_ai as prenom
from contact.contact;
create index m04_contact_prenom on outils.m04_contact (prenom);
analyze outils.m04_contact;

select prenom, count(*) as contacts
from outils.m04_contact
where prenom = 'elise'
group by prenom;
-- LIKE accepts a nondeterministic collation since PostgreSQL 18.
select count(*) as like_eli from outils.m04_contact where prenom like 'eli%';
-- ILIKE and regular expressions do not.
\set ON_ERROR_STOP off
select count(*) from outils.m04_contact where prenom ilike 'eli%';
select count(*) from outils.m04_contact where prenom ~ '^eli';
\set ON_ERROR_STOP on

-- Equality uses the index; LIKE does not.
explain (costs off) select count(*) from outils.m04_contact where prenom = 'elise';
explain (costs off) select count(*) from outils.m04_contact where prenom like 'eli%';

drop table outils.m04_contact;
drop collation outils.m04_ci;
drop collation outils.m04_ci_ai;

-- citext: an extension type that compares with lower(); accents still count.
select 'Élise'::citext = 'élise'::citext as citext_case,
       'Élise'::citext = 'elise'::citext as citext_accent;
