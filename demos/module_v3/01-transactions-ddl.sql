-- Clip V3.1: BEGIN without nesting, transactional DDL, the commands refused in a transaction,
-- psql's AUTOCOMMIT. Lab database, psql. Creates outils.mv3_draft and rolls it back; two
-- statements fail on purpose: ON_ERROR_STOP is off around them.

-- 1. No nested transactions. The T-SQL habit: BEGIN TRAN twice, then COMMIT twice.
begin;
insert into outils.mv3_inscription (inscriptionid, sessionid) values (900001, 41);
begin;                                    -- a warning, still one transaction
insert into outils.mv3_inscription (inscriptionid, sessionid) values (900002, 41);
commit;                                   -- the "inner" COMMIT commits both rows
rollback;                                 -- a warning, nothing left to roll back
select inscriptionid from outils.mv3_inscription where inscriptionid >= 900000 order by 1;
delete from outils.mv3_inscription where inscriptionid >= 900000;

-- 2. DDL in a transaction: a table, its rows and its index, rolled back together.
begin;
create table outils.mv3_draft (id int primary key, label text);
insert into outils.mv3_draft select g, 'draft ' || g from generate_series(1, 1000) g;
create index on outils.mv3_draft (label);
alter table outils.mv3_draft add column created timestamptz default now();
select count(*) as rows_in_draft from outils.mv3_draft;
rollback;
select to_regclass('outils.mv3_draft') as draft_after_rollback;

-- 3. What refuses to run in a transaction block (SQLSTATE 25001).
\set ON_ERROR_STOP off
begin;
create index concurrently on outils.mv3_inscription (contactid);
\echo SQLSTATE :SQLSTATE
rollback;
begin;
vacuum outils.mv3_inscription;
\echo SQLSTATE :SQLSTATE
rollback;
begin;
create database mv3_refused;              -- refused before anything is created
\echo SQLSTATE :SQLSTATE
rollback;
\set ON_ERROR_STOP on

-- 4. psql with AUTOCOMMIT off, like SET IMPLICIT_TRANSACTIONS ON: psql sends BEGIN
--    before the first statement, and nothing is committed until COMMIT.
\set AUTOCOMMIT off
insert into outils.mv3_inscription (inscriptionid, sessionid) values (900003, 41);
select pg_current_xact_id_if_assigned() is not null as in_transaction;
rollback;
\set AUTOCOMMIT on
select count(*) as left_rows from outils.mv3_inscription where inscriptionid >= 900000;
