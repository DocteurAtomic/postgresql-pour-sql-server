-- ci: skip (three sessions: play it one second after 04a-holder.sql, see scene.sh)
-- Clip 3.4, session B: updates the same row, and waits until A commits.
\timing on
update outils.m03_session set prix = prix + 10 where sessionid = 40;
\timing off
