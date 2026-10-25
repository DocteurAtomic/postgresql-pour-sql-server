-- ci: skip
-- Module D8 exercise, solution: the profile of stage.session in PostgreSQL, computed as
-- 3-profile-mssql.sql computes it in SQL Server (psql -At, in pgd8-expg).
select string_agg(format(
    'select %L || ''|'' || concat_ws(''|'', count(%I), %s, %s, %s) from %I.%I',
    table_schema || '.' || table_name || '|' || column_name, column_name,
    case
      when data_type in ('integer', 'smallint', 'bigint', 'numeric', 'double precision', 'real')
        then format('coalesce(sum(%I::numeric(38,4))::text, '''')', column_name)
      when data_type = 'boolean' then format('coalesce(sum(%I::int)::text, '''')', column_name)
      when data_type in ('character', 'character varying', 'text')
        then format('coalesce(sum(char_length(%I))::text, '''')', column_name)
      else ''''''
    end,
    case
      when data_type in ('integer', 'smallint', 'bigint', 'numeric', 'double precision', 'real')
        then format('coalesce(min(%I)::numeric(38,4)::text, '''')', column_name)
      when data_type = 'boolean' then format('coalesce(min(%I::int)::text, '''')', column_name)
      when data_type = 'date' then format('coalesce(to_char(min(%I), ''YYYY-MM-DD''), '''')', column_name)
      when data_type like 'timestamp%' then format('coalesce(to_char(min(%I), ''YYYY-MM-DD HH24:MI:SS''), '''')', column_name)
      when data_type = 'character' then format('coalesce(min(%I collate "C")::text, '''')', column_name)
      else ''''''
    end,
    case
      when data_type in ('integer', 'smallint', 'bigint', 'numeric', 'double precision', 'real')
        then format('coalesce(max(%I)::numeric(38,4)::text, '''')', column_name)
      when data_type = 'boolean' then format('coalesce(max(%I::int)::text, '''')', column_name)
      when data_type = 'date' then format('coalesce(to_char(max(%I), ''YYYY-MM-DD''), '''')', column_name)
      when data_type like 'timestamp%' then format('coalesce(to_char(max(%I), ''YYYY-MM-DD HH24:MI:SS''), '''')', column_name)
      when data_type = 'character' then format('coalesce(max(%I collate "C")::text, '''')', column_name)
      else ''''''
    end,
    table_schema, table_name), E'\nunion all ')
from information_schema.columns
where table_schema = 'stage' and table_name = 'session'
\gexec
