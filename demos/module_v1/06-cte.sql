-- Clip V1.6: WITH RECURSIVE, the missing MAXRECURSION, MATERIALIZED, the CTE that modifies.
-- Lab database, psql. The last part works on two copies created here and dropped at the
-- end. Two statements fail on purpose: ON_ERROR_STOP is off around them.

-- The T-SQL habit: a recursive CTE without the RECURSIVE keyword.
\set ON_ERROR_STOP off
with years as (
    select 2011 as year
    union all
    select year + 1 from years where year < 2016
)
select year from years;
\set ON_ERROR_STOP on

-- WITH RECURSIVE: the sessions per year, empty years included.
with recursive years as (
    select 2011 as year
    union all
    select year + 1 from years where year < 2016
)
select y.year, count(s.sessionid) as sessions
from years y
left join stage.session s on extract(year from s.datedebut) = y.year
group by y.year
order by y.year;

-- The same list without recursion: generate_series.
select y.year, count(s.sessionid) as sessions
from generate_series(2011, 2016) as y(year)
left join stage.session s on extract(year from s.datedebut) = y.year
group by y.year
order by y.year;

-- No MAXRECURSION, no limit of 100: a recursion without an end runs until something stops
-- it. Here, a statement timeout set for this session only.
set statement_timeout = '2s';
\set ON_ERROR_STOP off
with recursive n(i) as (
    select 1
    union all
    select i + 1 from n
)
select count(*) from n;
\set ON_ERROR_STOP on
reset statement_timeout;

-- Referenced once, a CTE is folded into the query (12): the index on sessionid serves.
explain (costs off)
with s as (select sessionid, stageid, datedebut from stage.session)
select sessionid, datedebut from s where sessionid = 971;

-- MATERIALIZED computes it first, as written: the whole table, then the filter.
explain (costs off)
with s as materialized (select sessionid, stageid, datedebut from stage.session)
select sessionid, datedebut from s where sessionid = 971;

-- A CTE that modifies: DELETE ... RETURNING feeds an INSERT, instead of OUTPUT INTO.
create table outils.mv1_session as
select sessionid, stageid, datedebut, prix from stage.session;
create table outils.mv1_session_archive (like outils.mv1_session);

with moved as (
    delete from outils.mv1_session
    where datedebut < date '2012-01-01'
    returning sessionid, stageid, datedebut, prix
)
insert into outils.mv1_session_archive
select sessionid, stageid, datedebut, prix from moved;

select (select count(*) from outils.mv1_session) as remaining,
       (select count(*) from outils.mv1_session_archive) as archived;

drop table outils.mv1_session_archive;
drop table outils.mv1_session;
