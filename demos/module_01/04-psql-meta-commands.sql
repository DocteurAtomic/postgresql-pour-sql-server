-- Clip 1.4: psql meta-commands. Plays in psql, inside the container. Read only.
-- Typed one by one at the prompt in the video; \e opens an editor and is not in the script.

-- Lists: databases, schemas, the tables of one schema.
\l
\dn
\dt stage.*

-- Describe a table (sp_help in SQL Server); \d+ adds storage and size.
\d stage.session

-- Expanded display, one column per line.
\x on
select * from stage.session where sessionid = (select min(sessionid) from stage.session);
\x off

-- Time each statement.
\timing on
select count(*) from inscription.inscription;
\timing off

-- Generate statements and execute them: the row count of every table of a schema.
select format('select %L as table_name, count(*) as row_count from %I.%I',
              schemaname || '.' || tablename, schemaname, tablename)
from pg_tables
where schemaname = 'stage'
order by tablename
\gexec

-- Run a file: \i takes a path, \ir a path relative to the current script.
\ir 01-lab-check.sql

-- Re-run a query every second, three times.
select to_char(now(), 'HH24:MI:SS') as at, count(*) as sessions
from stage.session
\watch i=1 c=3
