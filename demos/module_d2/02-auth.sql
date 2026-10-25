-- Clip D2.2: how the lab authenticates a connection. Lab database, psql. Read only.
-- pg_hba.conf, as the server read it: the first line that matches decides.
select line_number, type, database, user_name, address, auth_method
from pg_hba_file_rules
order by rule_number;

-- How a new password is stored, and whether the connections can be encrypted.
select name, setting
from pg_settings
where name in ('password_encryption', 'md5_password_warnings', 'ssl', 'listen_addresses')
order by name;

-- The roles of the module store a SCRAM hash, never the password.
select rolname, split_part(rolpassword, '$', 1) as hash_method
from pg_authid
where rolname like 'md2\_%' and rolpassword is not null
order by rolname;

-- This connection: through the socket of the container, so a "local" line.
select inet_client_addr() as client_address, ssl
from pg_stat_ssl
where pid = pg_backend_pid();
