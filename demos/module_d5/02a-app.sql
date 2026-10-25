-- ci: skip
-- Clip D5.2, session A of the scene played by ../module_03/scene.sh with 02b to 02e:
-- the application that updates session 40 and forgets its transaction (idle in
-- transaction during the shell sleep). The observer terminates it.
set application_name = 'md5-app';
begin;
update outils.md5_session set prix = prix + 10 where sessionid = 40;
\! sleep 15
commit;
