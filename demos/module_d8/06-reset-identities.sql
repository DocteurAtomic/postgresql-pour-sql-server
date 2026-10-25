-- ci: skip
-- Clip D8.6: every identity sequence moved past the largest value of its column, before the
-- applications write. Run by 06-cutover.sh in its throwaway container, after the load.
-- setval(seq, max + 1, false): the next value is max + 1. An empty table restarts at 1.
select format('select setval(%L, coalesce((select max(%I) from %I.%I), 0) + 1, false)',
              pg_get_serial_sequence(format('%I.%I', table_schema, table_name), column_name),
              column_name, table_schema, table_name)
from information_schema.columns
where is_identity = 'YES' and table_schema not in ('pg_catalog', 'information_schema')
order by table_schema, table_name
\gexec
