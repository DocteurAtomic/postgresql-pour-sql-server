-- ci: skip
-- Clip D8.2: reading SQL Server from PostgreSQL with tds_fdw. Run by 02-tds-fdw.sh in the
-- throwaway container pgd8-fdw (database pachadata), where the extension is installed.
-- The password comes from the environment of the container, never from this file.
\set ON_ERROR_STOP 1
set client_min_messages = warning;   -- tds_fdw sends two NOTICE lines per query
create extension tds_fdw;
select extversion from pg_extension where extname = 'tds_fdw';

\getenv mssql_host MSSQL_HOST
\getenv mssql_port MSSQL_PORT
\getenv mssql_db MSSQL_DB
\getenv mssql_user MSSQL_USER
\getenv mssql_password MSSQL_PASSWORD
create server mssql foreign data wrapper tds_fdw
    options (servername :'mssql_host', port :'mssql_port', database :'mssql_db');
create user mapping for postgres server mssql
    options (username :'mssql_user', password :'mssql_password');

-- One table of the source, its columns and types read from SQL Server.
create schema src;
import foreign schema "Stage" limit to ("Session") from server mssql into src;
\d src."Session"

-- The WHERE clause and the column list go to SQL Server.
explain (verbose, costs off)
select "SessionId", "Prix" from src."Session" where "Statut" = 'ANNULEE';
select count(*) as sessions, sum("Prix") as total_price from src."Session" where "Statut" = 'ANNULEE';

-- An aggregate does not: SQL Server sends the rows, PostgreSQL counts them.
explain (verbose, costs off)
select count(*) from src."Session" where "Prix" > 2000;

-- A query of its own, run by SQL Server. Columns are matched by name, case included.
create foreign table src.session_by_status (statut text, sessions int)
    server mssql options (query 'SELECT Statut, COUNT(*) AS sessions FROM Stage.Session GROUP BY Statut');
select statut, sessions from src.session_by_status order by sessions;

create foreign table src.session_by_status_named (statut text, sessions int)
    server mssql options (query 'SELECT Statut AS statut, COUNT(*) AS sessions FROM Stage.Session GROUP BY Statut');
select statut, sessions from src.session_by_status_named order by sessions;
