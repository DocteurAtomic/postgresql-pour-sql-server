-- Clip V1.2: CROSS APPLY and OUTER APPLY become LATERAL joins; DISTINCT ON. Lab database, psql.
-- Read only. One statement fails on purpose: ON_ERROR_STOP is off around it.

-- A subquery in FROM cannot see the tables before it, unless it is LATERAL.
\set ON_ERROR_STOP off
select sl.titre, last2.sessionid
from stage.stagelangue sl
cross join (select s.sessionid from stage.session s
            where s.stageid = sl.stageid
            order by s.datedebut desc limit 2) as last2
where sl.titre like 'PostgreSQL 9%';
\set ON_ERROR_STOP on

-- CROSS APPLY: CROSS JOIN LATERAL. The two latest sessions from July 2020, per course.
select sl.titre, last2.sessionid, last2.datedebut
from stage.stagelangue sl
cross join lateral (select s.sessionid, s.datedebut
                    from stage.session s
                    where s.stageid = sl.stageid and s.languecd = sl.languecd
                      and s.datedebut >= date '2020-07-01'
                    order by s.datedebut desc
                    limit 2) as last2
where sl.titre like 'PostgreSQL 9%'
order by sl.titre, last2.datedebut desc;

-- OUTER APPLY: LEFT JOIN LATERAL ... ON true keeps the courses without a session.
select sl.titre, last2.sessionid, last2.datedebut
from stage.stagelangue sl
left join lateral (select s.sessionid, s.datedebut
                   from stage.session s
                   where s.stageid = sl.stageid and s.languecd = sl.languecd
                     and s.datedebut >= date '2020-07-01'
                   order by s.datedebut desc
                   limit 2) as last2 on true
where sl.titre like 'PostgreSQL 9%'
order by sl.titre, last2.datedebut desc;

-- The same top N per group with ROW_NUMBER, written the same way in both engines.
select titre, sessionid, datedebut
from (select sl.titre, s.sessionid, s.datedebut,
             row_number() over (partition by s.stageid order by s.datedebut desc) as rn
      from stage.stagelangue sl
      join stage.session s on s.stageid = sl.stageid and s.languecd = sl.languecd
      where sl.titre like 'PostgreSQL 9%' and s.datedebut >= date '2020-07-01') as ranked
where rn <= 2
order by titre, datedebut desc;

-- Top 1 per group: DISTINCT ON keeps the first row of each group, in ORDER BY order.
select distinct on (s.stageid) sl.titre, s.sessionid, s.datedebut
from stage.session s
join stage.stagelangue sl on sl.stageid = s.stageid and sl.languecd = s.languecd
where sl.titre like 'PostgreSQL 9%'
order by s.stageid, s.datedebut desc;

-- A set-returning function in FROM sees the tables before it, without the LATERAL keyword:
-- the five days of session 971, from its start date and the length of its course.
select s.sessionid, d.day::date as day
from stage.session s
join stage.stage st on st.stageid = s.stageid,
     generate_series(s.datedebut, s.datedebut + st.duree - 1, interval '1 day') as d(day)
where s.sessionid = 971
order by d.day;
