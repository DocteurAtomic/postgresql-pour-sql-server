-- Module V1 exercise, solution. Lab database, psql.
-- Query 4 works on a copy, outils.mv1_exercise, dropped at the end.

-- 1. LIMIT or FETCH FIRST ... WITH TIES, COALESCE, + 4 on a date. The trap: the four 2020
--    sessions without a price sort first in a descending sort; NULLS LAST puts them back.
--    The direct translation first, then the right one.
select sessionid, prix
from stage.session
where datedebut >= date '2020-01-01' and datedebut < date '2021-01-01'
order by prix desc
fetch first 5 rows with ties;

select sessionid, datedebut, datedebut + 4 as datefin, coalesce(note, 0) as note, prix
from stage.session
where datedebut >= date '2020-01-01' and datedebut < date '2021-01-01'
order by prix desc nulls last
fetch first 5 rows with ties;

-- 2. OUTER APPLY: LEFT JOIN LATERAL ... ON true.
select l.nom as lieu, last1.sessionid, last1.datedebut, sf.nom as salle
from reference.lieuformation l
left join lateral (select s.sessionid, s.datedebut, s.salleformationid
                   from stage.session s
                   join reference.salleformation sf2 on sf2.salleformationid = s.salleformationid
                   where sf2.lieuformationid = l.lieuformationid
                   order by s.datedebut desc
                   limit 1) as last1 on true
left join reference.salleformation sf on sf.salleformationid = last1.salleformationid
order by l.nom;

-- 3. FILTER replaces SUM(CASE ...), and percentile_cont is an aggregate: GROUP BY, no
--    DISTINCT and no OVER.
select sl.titre,
       count(*) filter (where extract(year from s.datedebut) = 2019) as sessions2019,
       count(*) filter (where extract(year from s.datedebut) = 2020) as sessions2020,
       percentile_cont(0.5) within group (order by s.prix) as prixmedian
from stage.stagelangue sl
join stage.session s on s.stageid = sl.stageid and s.languecd = sl.languecd
where sl.titre like 'PostgreSQL 9 %'
group by sl.titre
order by sl.titre;

-- 4. The alias on the target, the other tables in FROM, the join in WHERE; RETURNING with
--    OLD and NEW (18) replaces OUTPUT deleted and inserted. Repeating the target table in
--    FROM would update every session of the copy.
create table outils.mv1_exercise as
select sessionid, salleformationid, datedebut, prix from stage.session;

-- The direct translation, the target repeated in FROM, in a transaction rolled back:
-- a self-join that updates every row of the copy.
begin;
update outils.mv1_exercise set prix = s.prix * 1.05
from outils.mv1_exercise s
join reference.salleformation sf on sf.salleformationid = s.salleformationid
join reference.lieuformation l on l.lieuformationid = sf.lieuformationid
where l.nom = 'Centre Pacha Genève'
  and s.datedebut >= date '2012-01-01' and s.datedebut < date '2013-01-01';
rollback;

-- The right one.
update outils.mv1_exercise s
set prix = s.prix * 1.05
from reference.salleformation sf
join reference.lieuformation l on l.lieuformationid = sf.lieuformationid
where sf.salleformationid = s.salleformationid
  and l.nom = 'Centre Pacha Genève'
  and s.datedebut >= date '2012-01-01' and s.datedebut < date '2013-01-01'
returning s.sessionid, old.prix as ancienprix, new.prix as nouveauprix;
drop table outils.mv1_exercise;

-- 5. generate_series replaces the recursive CTE (WITH RECURSIVE would also work), and
--    there is no MAXRECURSION to set.
select m.mois::date as mois, count(s.sessionid) as sessions
from generate_series(date '2012-01-01', date '2012-12-01', interval '1 month') as m(mois)
left join stage.session s
       on s.datedebut >= m.mois and s.datedebut < m.mois + interval '1 month'
group by m.mois
order by m.mois;
