-- ci: skip
-- Clip D5.2, session D: a report that only reads the table, and waits in the queue behind
-- the ALTER TABLE of C (module 3, clip 4).
set application_name = 'md5-report';
\timing on
select count(*) as sessions from outils.md5_session;
