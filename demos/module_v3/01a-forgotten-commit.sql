-- ci: skip (two sessions: play it with 01b-observer.sql, see scene.sh)
-- Clip V3.1, session A: a client in autocommit off that updates a row and forgets to
-- commit. The session-level timeout ends it. \! sleep keeps psql busy without sending
-- anything: the server sees the session idle, inside its transaction.
set idle_in_transaction_session_timeout = '3s';
\set AUTOCOMMIT off
update outils.mv3_inscription set contactid = contactid where inscriptionid = 100;
\! sleep 5
select 'still here' as status;
