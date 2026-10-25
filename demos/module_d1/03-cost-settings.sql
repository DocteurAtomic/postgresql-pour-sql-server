-- Clip D1.3: random_page_cost and effective_cache_size change estimates, not memory. Lab
-- database, psql. SET changes this session only; RESET puts the instance values back.
set max_parallel_workers_per_gather = 0;     -- one process, plans easier to compare

-- 44 % of the registrations: with the default random_page_cost (4), a sequential scan.
explain (analyze, costs off, timing off)
select contactid, sessionid
from inscription.inscription
where contactid between 1000 and 12000;

-- The value often copied for SSD storage: the index looks cheap enough.
set random_page_cost = 1.1;
explain (analyze, costs off, timing off)
select contactid, sessionid
from inscription.inscription
where contactid between 1000 and 12000;

-- effective_cache_size allocates nothing: it only tells the planner how much may be cached.
set effective_cache_size = '8MB';
explain (costs off)
select contactid, sessionid
from inscription.inscription
where contactid between 1000 and 12000;

reset effective_cache_size;
reset random_page_cost;
reset max_parallel_workers_per_gather;
