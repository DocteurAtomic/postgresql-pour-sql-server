-- Module 4 exercise, solution. Lab database, psql.
-- Creates outils.m04_exercise to show the conversion of statut, and drops it at the end.

-- 1. The char(n) columns, with what they really contain: non-null values, distinct values,
--    and the shortest and longest value once the padding is ignored.
--    One query per column, glued by UNION ALL, built by format() and run by \gexec.
select string_agg(
         format('select %L as column_name, %s as n, count(%I) as non_null, '
                'count(distinct %I) as distinct_values, min(length(%I)) as min_length, '
                'max(length(%I)) as max_length from %I.%I',
                table_schema || '.' || table_name || '.' || column_name, character_maximum_length,
                column_name, column_name, column_name, column_name, table_schema, table_name),
         ' union all ' order by table_schema, table_name, column_name)
       || ' order by 1'
from information_schema.columns
where table_schema not in ('pg_catalog', 'information_schema')
  and data_type = 'character'
\gexec

-- 2. A length of 0 is a value made of spaces only: inscription.facture.coderemise has them.
select count(*) filter (where coderemise is null) as null_values,
       count(*) filter (where length(coderemise) = 0) as spaces_only,
       count(*) filter (where coderemise::text = '') as empty_once_text
from inscription.facture;

-- 3. The values of the char(10), stage.session.statut.
select statut, count(*) as sessions
from stage.session
group by statut
order by statut;

-- 4. Converting a char(n) to text removes the padding: a copy of stage.session shows it.
create table outils.m04_exercise as
select sessionid, statut from stage.session where statut is not null;
select concat(statut, '|') as before, octet_length(statut) as bytes_before
from outils.m04_exercise limit 1;
alter table outils.m04_exercise alter column statut type text;
alter table outils.m04_exercise
    add constraint m04_exercise_statut check (statut in ('A'));
select concat(statut, '|') as after, octet_length(statut) as bytes_after
from outils.m04_exercise limit 1;
\d outils.m04_exercise

drop table outils.m04_exercise;
