-- Clip V6.4: vectors with pgvector (extension vector). Lab database, psql, after 00-setup.sql.
-- No embedding model: the vectors are built by hand (three dimensions) or computed from the
-- identifiers (sixteen dimensions), see 00-setup.sql. The script drops the HNSW index it
-- creates; its temporary tables vanish with the session. Building the graph takes about ten
-- seconds. The graph has a random part: the recall measured at the end can move by a few
-- rows from one build to the next.

-- 1. The type, and a distance per operator: <-> Euclidean (L2), <=> cosine, <#> negative
--    inner product, <+> L1 (taxicab).
select titre, embedding from outils.mv6_stage_vecteur where stageid in (103, 113) order by stageid;
select '[1,1]'::vector <-> '[-1,-1]' as l2, '[1,1]'::vector <=> '[-1,-1]' as cosine,
       '[1,1]'::vector <#> '[-1,-1]' as negative_inner_product, '[1,1]'::vector <+> '[-1,-1]' as l1;

-- 2. A course mostly about development, with some tuning: the nearest level of each kind.
select p.niveau, round(min(v.embedding <=> '[0.1, 0.8, 0.6]')::numeric, 3) as cosine_distance
from outils.mv6_stage_vecteur as v
join outils.mv6_programme as p using (stageid)
group by p.niveau
order by cosine_distance;

-- 3. 100,000 vectors of 16 dimensions. The ten nearest neighbours of vector 42, exactly: a
--    full scan. Then 100 query vectors computed the same way from ids that are not in the
--    table, and their exact neighbours, kept to measure the index.
select id, round((embedding <-> (select embedding from outils.mv6_vecteur where id = 42))::numeric, 4) as distance
from outils.mv6_vecteur
order by embedding <-> (select embedding from outils.mv6_vecteur where id = 42)
limit 10;
explain (analyze, costs off)
select id from outils.mv6_vecteur
order by embedding <-> (select embedding from outils.mv6_vecteur where id = 42)
limit 10;
create temp table mv6_query as
select id as qid,
       (select array_agg(abs(sin(id * 12.9898 + k * 78.233) * 43758.5453)
                         - floor(abs(sin(id * 12.9898 + k * 78.233) * 43758.5453))
                         order by k)
        from generate_series(1, 16) as k)::vector(16) as embedding
from generate_series(100001, 100100) as id;
create temp table mv6_exact as
select q.qid, n.id
from mv6_query as q
cross join lateral (select id from outils.mv6_vecteur
                    order by embedding <-> q.embedding limit 10) as n;

-- 4. The HNSW index: a graph, built for one distance. The query is approximate. With the
--    default maintenance_work_mem (64 MB), the graph does not fit and pgvector says so. In
--    the lab container, raising it to 256 MB fails: the parallel build puts the graph in
--    /dev/shm, which a container limits to 64 MB unless told otherwise (shm_size).
show maintenance_work_mem;
create index mv6_vecteur_hnsw on outils.mv6_vecteur using hnsw (embedding vector_l2_ops);
select pg_size_pretty(pg_relation_size('outils.mv6_vecteur'::regclass)) as table_size,
       pg_size_pretty(pg_relation_size('outils.mv6_vecteur_hnsw'::regclass)) as index_size;
explain (analyze, costs off)
select id from outils.mv6_vecteur
order by embedding <-> (select embedding from outils.mv6_vecteur where id = 42)
limit 10;

-- 5. Recall: how many of the 1,000 exact neighbours the index finds, for three values of
--    hnsw.ef_search (40 by default), the size of the candidate list.
show hnsw.ef_search;
select current_setting('hnsw.ef_search') as ef_search, count(*) as found
from mv6_exact
join (select q.qid, n.id from mv6_query as q
      cross join lateral (select id from outils.mv6_vecteur
                          order by embedding <-> q.embedding limit 10) as n) as approx
using (qid, id);
set hnsw.ef_search = 10;
select current_setting('hnsw.ef_search') as ef_search, count(*) as found
from mv6_exact
join (select q.qid, n.id from mv6_query as q
      cross join lateral (select id from outils.mv6_vecteur
                          order by embedding <-> q.embedding limit 10) as n) as approx
using (qid, id);
set hnsw.ef_search = 100;
select current_setting('hnsw.ef_search') as ef_search, count(*) as found
from mv6_exact
join (select q.qid, n.id from mv6_query as q
      cross join lateral (select id from outils.mv6_vecteur
                          order by embedding <-> q.embedding limit 10) as n) as approx
using (qid, id);
reset hnsw.ef_search;

-- 6. The index serves one operator: the cosine distance does not use an L2 index.
explain (costs off)
select id from outils.mv6_vecteur
order by embedding <=> (select embedding from outils.mv6_vecteur where id = 42)
limit 10;

-- 7. A filter on 1 % of the rows: the index returns its 40 candidates, the filter keeps
--    those of category 7, zero or one on average, and the query returns fewer rows than its
--    LIMIT. Iterative scans (pgvector 0.8) read further into the graph.
explain (analyze, costs off)
select id from outils.mv6_vecteur
where categorie = 7
order by embedding <-> (select embedding from outils.mv6_vecteur where id = 42)
limit 10;
set hnsw.iterative_scan = relaxed_order;
select count(*) as rows_returned
from (select id from outils.mv6_vecteur
      where categorie = 7
      order by embedding <-> (select embedding from outils.mv6_vecteur where id = 42)
      limit 10) as filtered;
reset hnsw.iterative_scan;

drop index outils.mv6_vecteur_hnsw;
