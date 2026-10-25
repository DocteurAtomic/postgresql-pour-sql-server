-- Clip V3.2: the aborted transaction, SAVEPOINT, psql's ON_ERROR_ROLLBACK.
-- Lab database, psql. Inserts into outils.mv3_inscription and removes what it inserts.
-- Statements fail on purpose: ON_ERROR_STOP is off for the whole script.
\set ON_ERROR_STOP off

-- 1. One error, and the whole transaction is lost. 900001 is inserted, 100 already exists.
begin;
insert into outils.mv3_inscription (inscriptionid, sessionid) values (900001, 41);
insert into outils.mv3_inscription (inscriptionid, sessionid) values (100, 41);
\echo SQLSTATE :SQLSTATE
select count(*) from outils.mv3_inscription where sessionid = 41;
\echo SQLSTATE :SQLSTATE
commit;                                   -- answered by ROLLBACK, with no error
select count(*) as kept from outils.mv3_inscription where inscriptionid = 900001;

-- 2. A savepoint before the statement that may fail, and ROLLBACK TO on error.
begin;
insert into outils.mv3_inscription (inscriptionid, sessionid) values (900001, 41);
savepoint before_second;
insert into outils.mv3_inscription (inscriptionid, sessionid) values (100, 41);
rollback to savepoint before_second;
insert into outils.mv3_inscription (inscriptionid, sessionid) values (900002, 41);
commit;
select inscriptionid from outils.mv3_inscription where inscriptionid >= 900000 order by 1;
delete from outils.mv3_inscription where inscriptionid >= 900000;

-- 3. psql does the same for each statement with ON_ERROR_ROLLBACK on: an implicit
--    savepoint before each statement of a transaction block, a subtransaction each time.
\set ON_ERROR_ROLLBACK on
begin;
insert into outils.mv3_inscription (inscriptionid, sessionid) values (900001, 41);
insert into outils.mv3_inscription (inscriptionid, sessionid) values (100, 41);
insert into outils.mv3_inscription (inscriptionid, sessionid) values (900002, 41);
commit;
\set ON_ERROR_ROLLBACK off
select inscriptionid from outils.mv3_inscription where inscriptionid >= 900000 order by 1;
delete from outils.mv3_inscription where inscriptionid >= 900000;
\set ON_ERROR_STOP on
