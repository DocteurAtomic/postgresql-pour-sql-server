-- Clip 4.2: text, varchar(n), char(n). Lab database, psql.

-- stage.session.statut is a char(10), the only one of the port: 'A' on 146 rows, NULL elsewhere.
select statut, count(*) as sessions
from stage.session
group by statut
order by statut;

-- char(n) pads with spaces and ignores them when comparing, but not everywhere.
select statut,
       length(statut) as length,
       octet_length(statut) as bytes,
       statut = 'A' as equals_a,
       statut like 'A' as like_a,
       statut || '|' as with_pipe,
       concat(statut, '|') as with_concat
from stage.session
where statut is not null
limit 1;

-- The same value in text and varchar: the spaces are significant.
select 'A '::varchar(10) = 'A'::varchar(10) as varchar_equal,
       'A '::char(10) = 'A'::char(10) as char_equal,
       length('A '::varchar(10)) as varchar_length;

-- varchar(n) is a limit, nothing more: too long is an error on insert,
-- a silent truncation in an explicit cast. varchar without n has no limit.
create temporary table m04_short (code varchar(5));
\set ON_ERROR_STOP off
insert into m04_short values ('PachaDataFormation');
\set ON_ERROR_STOP on
select cast('PachaDataFormation' as varchar(5)) as explicit_cast;
select length(repeat('x', 100000)::varchar) as varchar_without_n;
drop table m04_short;

-- || and NULL: NULL wins; concat() and concat_ws() skip it.
select 'Stage ' || null as pipe,
       concat('Stage ', null) as concat,
       concat_ws(', ', 'SQL Server', null, 'PostgreSQL') as concat_ws;
