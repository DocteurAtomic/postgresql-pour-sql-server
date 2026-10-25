-- Module 1 exercise: solution. Plays in psql, on the lab database. Read only: it creates
-- nothing, so there is nothing to clean.

-- 1. The server version, the size of the database, and the databases of the cluster.
select version();
select current_database(), pg_size_pretty(pg_database_size(current_database())) as size;
select datname from pg_database where not datistemplate order by datname;

-- 2. Tables and total size per schema, largest first.
select n.nspname as schema_name,
       count(*) as tables,
       pg_size_pretty(sum(pg_total_relation_size(c.oid))) as total_size
from pg_class as c
join pg_namespace as n on n.oid = c.relnamespace
where c.relkind = 'r'
  and n.nspname not in ('pg_catalog', 'information_schema')
group by n.nspname
order by sum(pg_total_relation_size(c.oid)) desc;

-- 3. The five largest tables, then the exact count of the largest.
select c.oid::regclass as table_name,
       c.reltuples::bigint as estimated_rows,
       pg_size_pretty(pg_total_relation_size(c.oid)) as total_size
from pg_class as c
join pg_namespace as n on n.oid = c.relnamespace
where c.relkind = 'r'
  and n.nspname not in ('pg_catalog', 'information_schema')
order by pg_total_relation_size(c.oid) desc
limit 5;
select count(*) as exact_rows from contact.prospectus;

-- 4. Tables without a primary key. A table of the public schema shows without its schema
--    name, because public is in the search_path.
select c.oid::regclass as table_name
from pg_class as c
join pg_namespace as n on n.oid = c.relnamespace
where c.relkind = 'r'
  and n.nspname not in ('pg_catalog', 'information_schema')
  and not exists (select 1
                  from pg_constraint as k
                  where k.conrelid = c.oid
                    and k.contype = 'p')
order by 1;

-- 5. Exact row count of every table of the schema inscription.
select format('select %L as table_name, count(*) as row_count from %I.%I',
              schemaname || '.' || tablename, schemaname, tablename)
from pg_tables
where schemaname = 'inscription'
order by tablename
\gexec

-- 6. The roles that can log in.
select rolname, rolsuper
from pg_roles
where rolcanlogin
order by rolname;
