-- Clip D8.6: every identity column, the last value of its sequence and the largest value in
-- the table. A next value below the maximum is a duplicate key waiting for the next INSERT.
-- Read only; lab database or the throwaway container of 06-cutover.sh, psql.
select count(*) as identity_columns
from information_schema.columns
where is_identity = 'YES' and table_schema not in ('pg_catalog', 'information_schema');

select string_agg(format(
    'select %L as identity_column, (select last_value from %s) as last_value, '
    '(select max(%I) from %I.%I) as max_value',
    c.table_schema || '.' || c.table_name || '.' || c.column_name,
    pg_get_serial_sequence(format('%I.%I', c.table_schema, c.table_name), c.column_name),
    c.column_name, c.table_schema, c.table_name), E'\nunion all ' order by c.table_schema, c.table_name)
    || E'\norder by 1'
from information_schema.columns c
where c.is_identity = 'YES' and c.table_schema not in ('pg_catalog', 'information_schema')
\gexec
