-- Clip 4.1: identifiers and case. Lab database, psql.
-- Three statements fail on purpose: ON_ERROR_STOP is off around them.

-- A table created the way a migration tool that keeps the SQL Server names would create it.
create table outils.m04_case ("SessionId" integer, "Statut" text, NomStage text);
\d outils.m04_case

-- Unquoted names are folded to lower case, quoted names keep their case.
\set ON_ERROR_STOP off
select SessionId from outils.m04_case;
\set ON_ERROR_STOP on
select "SessionId", nomstage, NOMSTAGE from outils.m04_case;

-- No square brackets: the delimiter is the double quote.
\set ON_ERROR_STOP off
select [SessionId] from outils.m04_case;
\set ON_ERROR_STOP on

drop table outils.m04_case;

-- The port of PachaDataFormation: no name with an upper-case letter.
select count(*) as mixed_case_names
from pg_class as c
join pg_namespace as n on n.oid = c.relnamespace
where n.nspname not in ('pg_catalog', 'information_schema', 'pg_toast')
  and c.relname <> lower(c.relname);
select count(*) as mixed_case_columns
from information_schema.columns
where table_schema not in ('pg_catalog', 'information_schema')
  and column_name <> lower(column_name);

-- 63 bytes at most: a longer name is truncated, with a notice and no error.
show max_identifier_length;
create table outils.m04_long (
    date_de_la_derniere_relance_envoyee_au_service_comptable_du_client integer);
select attname, length(attname) as characters
from pg_attribute
where attrelid = 'outils.m04_long'::regclass and attnum > 0;
drop table outils.m04_long;

-- What QUOTENAME does: quote a name only when it needs it.
select quote_ident('sessionid') as plain,
       quote_ident('SessionId') as mixed_case,
       quote_ident('order') as reserved_word,
       format('%I.%I', 'stage', 'Session') as with_format;
