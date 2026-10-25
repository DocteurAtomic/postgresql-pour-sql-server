-- Module 4 exercise, starting point. Lab database (pachadataformation), psql:
--   docker compose exec db psql -U postgres -d pachadataformation -f /exercises/module_04/1-inventory.sql
-- Lists the char(n) columns of the port. Read only: it creates nothing.
select table_schema, table_name, column_name, character_maximum_length as n, is_nullable
from information_schema.columns
where table_schema not in ('pg_catalog', 'information_schema')
  and data_type = 'character'
order by table_schema, table_name, column_name;
