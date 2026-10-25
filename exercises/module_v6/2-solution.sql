-- Module V6 exercise, solution. Lab database, psql, after 1-setup.sql.
-- Creates a normalization function, a trigram index and a search function, all in outils;
-- 3-cleanup.sql drops them.

-- Question 1: unaccent is STABLE, so it cannot go into an index. A wrapper that names its
-- dictionary can be declared IMMUTABLE; the index has to be rebuilt if the rules change.
create or replace function outils.mv6x_normalize(text) returns text
    language sql immutable parallel safe strict
    return lower(public.unaccent('public.unaccent'::regdictionary, $1));
select count(*) as normalized_developpement
from outils.mv6x_stage
where outils.mv6x_normalize(titre) like '%developpement%';

-- Question 2: a GiST index on the trigrams of the normalized title serves both % and the
-- <-> ordering (a GIN index serves % and LIKE, not the ordering).
create index mv6x_stage_titre_trgm on outils.mv6x_stage
    using gist (outils.mv6x_normalize(titre) gist_trgm_ops);
analyze outils.mv6x_stage;
set enable_seqscan = off;   -- 168 rows: without this, a full scan is cheaper
explain (costs off)
select stageid, titre
from outils.mv6x_stage
order by outils.mv6x_normalize(titre) <-> outils.mv6x_normalize('devlopement mysql')
limit 5;
reset enable_seqscan;

-- Question 3: the search function. The query goes through the same normalization.
create or replace function outils.mv6x_search(p_query text, p_limit integer default 5)
returns table (stageid integer, titre varchar, score numeric)
language sql stable parallel safe
begin atomic
    select s.stageid, s.titre,
           round(similarity(outils.mv6x_normalize(s.titre), outils.mv6x_normalize(p_query))::numeric, 2)
    from outils.mv6x_stage as s
    order by outils.mv6x_normalize(s.titre) <-> outils.mv6x_normalize(p_query), s.titre
    limit p_limit;
end;

-- Question 4: the four searches.
select q.query, r.*
from (values ('postgre optimisation'), ('devlopement mysql'),
             ('sql serveur avance'), ('firebird decouverte')) as q (query)
cross join lateral outils.mv6x_search(q.query, 3) as r
order by q.query, r.score desc, r.titre;

-- Question 5: Soundex keeps the first letter and three consonants: the 168 titles share
-- eight codes, and every PostgreSQL course has the code of the query.
select count(distinct soundex(titre)) as codes,
       count(*) filter (where soundex(titre) = soundex('postgre optimisation')) as same_code_as_query
from outils.mv6x_stage;
