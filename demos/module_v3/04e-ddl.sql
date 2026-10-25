-- ci: skip (three sessions: play it one second after 04d-worker.sql, see scene.sh)
-- Clip V3.4, session B: an ALTER TABLE asks for ACCESS EXCLUSIVE, which conflicts with
-- the ROW SHARE of worker A: it waits, in the lock queue of the table.
set application_name = 'migration';
\timing on
alter table outils.mv3_convocation add column priority int;
\timing off
alter table outils.mv3_convocation drop column priority;
