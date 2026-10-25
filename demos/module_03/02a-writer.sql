-- ci: skip (two sessions: play it with 02b-reader.sql, see scene.sh)
-- Clip 3.2, session A, the writer. Lab database, psql, after 00-setup.sql.
-- Updates the price of session 40, keeps the transaction open six seconds, then commits.
-- Start session B (02b-reader.sql) one second after this one.
update outils.m03_session set prix = 2500 where sessionid = 40;   -- the restored price

begin;
update outils.m03_session set prix = 2900 where sessionid = 40;
select pg_sleep(6);
commit;
