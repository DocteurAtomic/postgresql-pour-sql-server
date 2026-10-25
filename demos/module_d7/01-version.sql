-- Clip D7.1: the version of the lab, and what stands for a compatibility level. Lab
-- database, psql, read only.
select version();
show server_version_num;

-- No compatibility level: a handful of settings, one behavior each.
select name, setting
from pg_settings
where category = 'Version and Platform Compatibility / Previous PostgreSQL Versions'
order by name;
