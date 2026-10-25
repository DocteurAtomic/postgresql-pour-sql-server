-- Clip V7.1: connection strings, seen from psql. Lab database, psql:
--   docker compose exec db psql -U postgres -d pachadataformation -f /demos/module_v7/01-connection-strings.sql
-- The \! lines start a second psql inside the container, over TCP (127.0.0.1), as a client
-- program would; the lab trusts these local connections, so no password is asked.

-- The session of this psql, over the Unix socket.
\conninfo
select application_name, client_addr, backend_type
from pg_stat_activity where pid = pg_backend_pid();

-- The database comes from PGDATABASE, which libpq reads like every connection parameter.
\setenv PGDATABASE :DBNAME

-- A URI, with application_name and sslmode in its parameters.
\! psql "postgresql://postgres@127.0.0.1:5432/?application_name=pachadata-psql&sslmode=prefer" -X -c "select a.application_name, a.client_addr, s.ssl from pg_stat_activity a join pg_stat_ssl s using (pid) where a.pid = pg_backend_pid()"

-- A keyword/value string that requires TLS: the lab has none, the connection is refused.
\! psql "host=127.0.0.1 port=5432 user=postgres sslmode=require" -X -c "select 1"

-- The same parameters from the environment: PGAPPNAME for application_name.
\! PGAPPNAME=pachadata-env psql -h 127.0.0.1 -U postgres -X -c "show application_name"

show ssl;
