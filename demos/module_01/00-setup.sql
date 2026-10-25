-- Module 1, setup. Plays in psql, on the lab database (pachadataformation).
-- Module 1 creates nothing: no extension, no object. This script only checks that the lab
-- is the one the videos use, and stops with an error otherwise.
\set ON_ERROR_STOP on
select current_setting('server_version_num')::int >= 180000 as is_postgresql_18
\gset
\if :is_postgresql_18
\else
    \echo 'This course needs PostgreSQL 18.'
    select 1 / 0 as wrong_server_version;
\endif
select count(*) as user_tables
from pg_tables
where schemaname not in ('pg_catalog', 'information_schema');
