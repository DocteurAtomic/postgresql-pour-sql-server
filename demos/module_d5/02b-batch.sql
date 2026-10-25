-- ci: skip
-- Clip D5.2, session B: a batch that raises the prices of the stage of session 40, and so
-- waits for the row that A holds. Rolled back at the end, like C: the table stays as the
-- setup made it.
set application_name = 'md5-batch';
\timing on
begin;
update outils.md5_session set prix = prix * 1.05
where stageid = (select stageid from outils.md5_session where sessionid = 40);
rollback;
