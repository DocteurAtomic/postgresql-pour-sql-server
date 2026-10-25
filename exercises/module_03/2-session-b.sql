-- ci: skip (two sessions: play it one second after 2-session-a.sql)
-- Module 3 exercise, solution of question 1, session B: the same transaction as A. Its
-- UPDATE waits for A, then fails with SQLSTATE 40001; the retry, a new transaction,
-- succeeds.
begin transaction isolation level repeatable read;
select inscriptionid, remise from outils.m03_exercise where inscriptionid = 3;
select pg_sleep(2);
\set ON_ERROR_STOP off
\timing on
update outils.m03_exercise set remise = remise + 5 where inscriptionid = 3;
\timing off
\echo SQLSTATE :LAST_ERROR_SQLSTATE
\set ON_ERROR_STOP on
rollback;

-- The retry: the whole transaction again, which now sees A's update.
begin transaction isolation level repeatable read;
select inscriptionid, remise from outils.m03_exercise where inscriptionid = 3;
update outils.m03_exercise set remise = remise + 5 where inscriptionid = 3;
commit;
select inscriptionid, remise from outils.m03_exercise where inscriptionid = 3;
