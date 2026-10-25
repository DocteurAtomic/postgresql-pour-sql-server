-- ci: skip (four sessions: play it one second after 04d-reader.sql, see scene.sh)
-- Clip 3.4, session B: an ALTER TABLE asks for an ACCESS EXCLUSIVE lock and queues behind
-- A. lock_timeout limits the wait to three seconds; without it, B would wait for A.
set lock_timeout = '3s';
\set ON_ERROR_STOP off
\timing on
alter table outils.m03_session add column m03_note text;
\timing off
\echo SQLSTATE :LAST_ERROR_SQLSTATE
\set ON_ERROR_STOP on
