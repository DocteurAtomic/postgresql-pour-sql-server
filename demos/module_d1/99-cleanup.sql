-- Module D1, cleanup. Lab database, psql. The module created nothing in the database; the
-- throwaway containers of its .sh scripts remove themselves. This checks the lab instance
-- has no ALTER SYSTEM value left (postgresql.auto.conf empty).
select count(*) as auto_conf_settings
from pg_file_settings
where sourcefile like '%postgresql.auto.conf';
