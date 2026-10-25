-- ci: skip
-- Clip D8.3: what pgloader created, read in the throwaway container pgd8-schema
-- (database pachadata) by 03-convert-schema.sh. Not for the lab.
-- Column types of the five migrated schemas.
select data_type, count(*) as columns
from information_schema.columns
where table_schema in ('stage', 'inscription', 'formateur', 'contact', 'reference')
group by data_type
order by columns desc, data_type;

-- Identity columns and sequences: SQL Server has 14 identity columns in these tables.
select count(*) filter (where is_identity = 'YES') as identity_columns,
       count(*) filter (where column_default like 'nextval(%') as serial_columns,
       (select count(*) from pg_sequences) as sequences
from information_schema.columns
where table_schema in ('stage', 'inscription', 'formateur', 'contact', 'reference');

-- One table in full: columns, defaults and index names.
\d stage.session
