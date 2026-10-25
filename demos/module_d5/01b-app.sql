-- ci: skip
-- Clip D5.1, session B of the scene. An application that updates a row and then forgets
-- its transaction: during the shell sleep, psql sends nothing, the session is
-- "idle in transaction". The observer terminates it; the commit never reaches the server.
set application_name = 'md5-app';
begin;
update outils.md5_session set prix = prix + 10 where sessionid = 40;
\! sleep 12
commit;
