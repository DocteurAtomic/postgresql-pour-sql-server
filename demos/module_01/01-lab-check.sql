-- Clip 1.2: first queries on the lab. Plays in psql, inside the container:
--   docker compose exec db psql -U postgres -d pachadataformation
-- Read only.
select version();

-- Who am I, where am I. Inside the container psql connects through the Unix socket.
select current_user, current_database(), inet_server_port() as port;

-- The library the lab preloads (compose.yaml, command line of the server).
show shared_preload_libraries;

-- The addresses moved to .example by setup/anonymize.sql.
select count(email) as contacts_with_email,
       count(*) filter (where email like '%.example') as on_example_domains
from contact.contact;

-- How the server authenticates each connection (the rules of pg_hba.conf). In the lab image,
-- local connections are trusted; connections from outside the container need the password.
select line_number, type, database, user_name, address, auth_method
from pg_hba_file_rules
order by line_number;
