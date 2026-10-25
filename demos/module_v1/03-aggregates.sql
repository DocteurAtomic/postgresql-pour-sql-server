-- Clip V1.3: FILTER, string_agg, array_agg, percentile_cont, GROUPING SETS, a RANGE frame.
-- Lab database, psql. Read only. Two statements fail on purpose: ON_ERROR_STOP is off
-- around them.

-- SUM(CASE ...) and PIVOT: the FILTER clause. Sessions per year, intra and inter.
select extract(year from datedebut) as year,
       count(*) as sessions,
       count(*) filter (where intraentrerprise) as intra,
       count(*) filter (where not intraentrerprise) as inter,
       sum(prix) filter (where not intraentrerprise) as inter_revenue
from stage.session
where datedebut >= date '2018-01-01'
group by year
order by year;

-- STRING_AGG ... WITHIN GROUP (ORDER BY): the ORDER BY goes inside the parentheses.
select l.nom as venue, string_agg(sf.nom, ', ' order by sf.nom) as rooms
from reference.lieuformation l
join reference.salleformation sf on sf.lieuformationid = l.lieuformationid
group by l.nom
order by l.nom
limit 3;

-- array_agg: no T-SQL equivalent. An array is indexed from 1.
select sl.titre, array_agg(s.sessionid order by s.datedebut) as sessions,
       (array_agg(s.sessionid order by s.datedebut))[1] as first_session
from stage.stagelangue sl
join stage.session s on s.stageid = sl.stageid and s.languecd = sl.languecd
where sl.titre like 'PostgreSQL 9 Optimisation%' and s.datedebut >= date '2020-01-01'
group by sl.titre;

-- PERCENTILE_CONT is an ordered-set aggregate: GROUP BY, no OVER.
select extract(year from datedebut) as year,
       percentile_cont(0.5) within group (order by prix) as median_price,
       round(avg(prix), 2) as mean_price
from stage.session
where datedebut >= date '2018-01-01'
group by year
order by year;
\set ON_ERROR_STOP off
select distinct extract(year from datedebut) as year,
       percentile_cont(0.5) within group (order by prix)
           over (partition by extract(year from datedebut)) as median_price
from stage.session;
\set ON_ERROR_STOP on

-- GROUPING SETS and ROLLUP, as in T-SQL; WITH ROLLUP after GROUP BY does not exist.
select extract(year from datedebut) as year, intraentrerprise as intra, count(*) as sessions,
       grouping(extract(year from datedebut), intraentrerprise) as level
from stage.session
where datedebut >= date '2019-01-01'
group by rollup (extract(year from datedebut), intraentrerprise)
order by year, intra;
\set ON_ERROR_STOP off
select intraentrerprise, count(*) from stage.session group by intraentrerprise with rollup;
\set ON_ERROR_STOP on

-- A RANGE frame with an offset, which SQL Server refuses: for each session of the course
-- PostgreSQL 9 Optimisation, the sessions of the year before; ROWS counts rows, not time.
select sessionid, datedebut,
       count(*) over (order by datedebut
                      range between interval '1 year' preceding and current row) as previous_year,
       count(*) over (order by datedebut
                      rows between 3 preceding and current row) as last_4_rows
from stage.session
where stageid = 119 and datedebut < date '2018-01-01'
order by datedebut;
