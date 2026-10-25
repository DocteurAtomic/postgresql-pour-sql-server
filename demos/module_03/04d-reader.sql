-- ci: skip (four sessions: play it with 04e-ddl.sql, 04f-reader.sql, 04g-observer.sql)
-- Clip 3.4, session A: a reading transaction left open seven seconds. Its SELECT holds
-- an ACCESS SHARE lock on the table until the end of the transaction.
begin;
select count(*) from outils.m03_session;
select pg_sleep(7);
commit;
