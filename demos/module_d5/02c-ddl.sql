-- ci: skip
-- Clip D5.2, session C: a schema change, which needs an ACCESS EXCLUSIVE lock on the table
-- and waits for A and B. Rolled back at the end: the table keeps its columns.
set application_name = 'md5-ddl';
\timing on
begin;
alter table outils.md5_session add column remarque text;
rollback;
