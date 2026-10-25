-- Clip V6.2: full text search. Lab database, psql, after 00-setup.sql.
-- Runs on outils.mv6_programme. Two statements fail on purpose; the script drops the index
-- and the column it creates.
\set ON_ERROR_STOP off

-- 1. A document becomes a tsvector: words cut, stop words removed, stems kept with their
--    positions. The configuration chooses the language.
select programme from outils.mv6_programme where stageid = 103;
select to_tsvector('french', 'Les sauvegardes et les restaurations des bases');

-- 2. A question becomes a tsquery, and @@ compares them.
select plainto_tsquery('french', 'sauvegarde des bases'),
       websearch_to_tsquery('french', 'sauvegarde -oracle "plans d''exécution"');
select count(*) as courses
from outils.mv6_programme
where to_tsvector('french', programme) @@ plainto_tsquery('french', 'bases de données');

-- 3. Without a configuration, the functions take default_text_search_config, which initdb
--    set from the locale of the lab: english. The English stemmer does not cut "bases" the
--    way the French one did.
show default_text_search_config;
select plainto_tsquery('bases de données') as english, plainto_tsquery('french', 'bases de données') as french;
select count(*) as courses
from outils.mv6_programme
where to_tsvector('french', programme) @@ plainto_tsquery('bases de données');

-- 4. Ranking and highlighting.
select titre, ts_rank(to_tsvector('french', programme), q) as rank
from outils.mv6_programme, websearch_to_tsquery('french', 'index or requêtes or postgresql') as q
where to_tsvector('french', programme) @@ q
order by rank desc, titre
limit 5;
select ts_headline('french', programme, websearch_to_tsquery('french', 'plans d''exécution'),
                   'MaxFragments=1, MaxWords=12, MinWords=6') as extract
from outils.mv6_programme
where stageid = 103;

-- 5. The index. The one-argument to_tsvector depends on a setting: it cannot be indexed.
create index mv6_programme_fts on outils.mv6_programme using gin (to_tsvector(programme));
create index mv6_programme_fts on outils.mv6_programme using gin (to_tsvector('french', programme));
-- The query must repeat the same expression, configuration included.
explain (costs off)
select stageid from outils.mv6_programme
where to_tsvector('french', programme) @@ plainto_tsquery('french', 'sauvegarde');
explain (costs off)
select stageid from outils.mv6_programme
where to_tsvector(programme) @@ plainto_tsquery('french', 'sauvegarde');
drop index outils.mv6_programme_fts;

-- 6. Or a generated column. In PostgreSQL 18, a generated column is virtual by default, and
--    a virtual column cannot be indexed: it has to be STORED.
alter table outils.mv6_programme
    add column programme_tsv tsvector generated always as (to_tsvector('french', programme));
create index mv6_programme_tsv on outils.mv6_programme using gin (programme_tsv);
alter table outils.mv6_programme drop column programme_tsv;
alter table outils.mv6_programme
    add column programme_tsv tsvector generated always as (to_tsvector('french', programme)) stored;
create index mv6_programme_tsv on outils.mv6_programme using gin (programme_tsv);
explain (costs off)
select stageid from outils.mv6_programme
where programme_tsv @@ plainto_tsquery('french', 'sauvegarde');
alter table outils.mv6_programme drop column programme_tsv;

-- 7. The French configuration keeps the accents: a question typed without them misses.
select count(*) as with_accent
from outils.mv6_programme
where to_tsvector('french', programme) @@ plainto_tsquery('french', 'déclencheurs');
select count(*) as without_accent
from outils.mv6_programme
where to_tsvector('french', programme) @@ plainto_tsquery('french', 'declencheurs');

\set ON_ERROR_STOP on
