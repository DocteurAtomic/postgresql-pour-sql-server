-- Clip 1.3: the vocabulary, read in the system catalogs. Plays in psql. Read only.

-- The databases of the cluster (what \l lists).
select datname, datistemplate, datallowconn
from pg_database
order by datname;

-- Roles are defined once for the whole cluster. Roles whose name starts with pg_ are
-- the predefined roles of PostgreSQL.
select rolname, rolcanlogin, rolsuper
from pg_roles
where rolname !~ '^pg_';
select count(*) as predefined_roles
from pg_roles
where rolname ~ '^pg_';

-- Tablespaces: two at the start, pg_default for the data, pg_global for shared catalogs.
select spcname
from pg_tablespace
order by spcname;

-- Inside the database: the schemas and what they contain. relkind r = table,
-- i = index, S = sequence, v = view, m = materialized view.
select n.nspname as schema_name,
       count(*) filter (where c.relkind = 'r') as tables,
       count(*) filter (where c.relkind = 'i') as indexes,
       count(*) filter (where c.relkind = 'S') as sequences,
       count(*) filter (where c.relkind in ('v', 'm')) as views
from pg_namespace as n
left join pg_class as c on c.relnamespace = n.oid
where n.nspname not like 'pg\_%'
  and n.nspname <> 'information_schema'
group by n.nspname
order by n.nspname;

-- The connection: one database, one role, one current schema.
select current_database(), current_user, current_schema;

-- The page size, fixed when PostgreSQL was compiled.
show block_size;

-- A relation and its pages: stage.session, after vacuumdb --analyze.
select relname, relkind, relpages, reltuples::bigint as estimated_rows
from pg_class
where oid = 'stage.session'::regclass;
