-- Clip V6.3: similarity and accents. Lab database, psql, after 00-setup.sql.
-- Runs on outils.mv6_contact (a copy of the contacts' names) and outils.mv6_programme. One
-- statement fails on purpose. The script drops the indexes, the function and the text search
-- configuration it creates.
\set ON_ERROR_STOP off

-- 1. fuzzystrmatch has the SOUNDEX and DIFFERENCE of SQL Server, and the Levenshtein
--    distance. Its documentation warns that soundex does not handle multibyte characters.
select soundex('Lefebvre') as lefebvre, soundex('Lefevre') as lefevre,
       difference('Lefebvre', 'Lefevre') as difference, levenshtein('Lefebvre', 'Lefevre') as levenshtein;
select soundex('Elise') as elise, soundex('Élise') as elise_accent;
select string_agg(distinct nom, ', ') as same_soundex
from outils.mv6_contact
where soundex(nom) = soundex('Lefevre');

-- 2. pg_trgm: the share of trigrams two strings have in common, from 0 to 1.
select show_trgm('Lefevre');
select similarity('Lefevre', 'Lefebvre') as lefebvre, similarity('Lefevre', 'Lefeuvre') as lefeuvre,
       similarity('Lefevre', 'Martin') as martin;

-- 3. The % operator keeps what is above pg_trgm.similarity_threshold (0.3); <-> is the
--    distance, 1 - similarity, to sort by.
show pg_trgm.similarity_threshold;
select nom, round(similarity(nom, 'Lefevre')::numeric, 2) as similarity
from (select distinct nom from outils.mv6_contact) as names
where nom % 'Lefevre'
order by nom <-> 'Lefevre', nom
limit 6;

-- 4. The five nearest names, without and with a GiST index on the trigrams: GIN serves %,
--    only GiST also returns the rows in distance order.
explain (analyze, costs off)
select contactid, nom from outils.mv6_contact order by nom <-> 'Lefevre' limit 5;
create index mv6_contact_nom_trgm on outils.mv6_contact using gist (nom gist_trgm_ops);
explain (analyze, costs off)
select contactid, nom from outils.mv6_contact order by nom <-> 'Lefevre' limit 5;
drop index outils.mv6_contact_nom_trgm;

-- 5. unaccent removes the accents. The data has 123 Hélène and no Helene.
select unaccent('Hélène Français Œuvre');
select count(*) filter (where prenom = 'Helene') as equal,
       count(*) filter (where unaccent(prenom) = 'Helene') as unaccented
from outils.mv6_contact;

-- 6. unaccent is STABLE, not IMMUTABLE: its result depends on a dictionary that can be
--    altered. It cannot go into an index...
select p.oid::regprocedure as function, p.provolatile as volatility
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where p.proname = 'unaccent' and n.nspname = 'public';
create index mv6_contact_prenom_unaccent on outils.mv6_contact (unaccent(prenom));
-- ... unless a wrapper names the dictionary and declares itself IMMUTABLE. The promise is
-- ours: if the rules of the dictionary change, the index has to be rebuilt.
create function outils.mv6_unaccent(text) returns text
    language sql immutable parallel safe strict
    return public.unaccent('public.unaccent'::regdictionary, $1);
create index mv6_contact_prenom_unaccent on outils.mv6_contact (lower(outils.mv6_unaccent(prenom)));
analyze outils.mv6_contact;
explain (analyze, costs off)
select contactid, prenom from outils.mv6_contact
where lower(outils.mv6_unaccent(prenom)) = 'helene';
drop index outils.mv6_contact_prenom_unaccent;

-- 7. The same dictionary in a text search configuration: the French configuration, with
--    unaccent before the French stemmer. The search without accents now finds the courses.
create text search configuration outils.mv6_french_unaccent (copy = french);
alter text search configuration outils.mv6_french_unaccent
    alter mapping for hword, hword_part, word with unaccent, french_stem;
select to_tsvector('outils.mv6_french_unaccent', 'procédures stockées et déclencheurs');
select count(*) as without_accent
from outils.mv6_programme
where to_tsvector('outils.mv6_french_unaccent', programme)
      @@ plainto_tsquery('outils.mv6_french_unaccent', 'declencheurs');
drop text search configuration outils.mv6_french_unaccent;
drop function outils.mv6_unaccent(text);

\set ON_ERROR_STOP on
