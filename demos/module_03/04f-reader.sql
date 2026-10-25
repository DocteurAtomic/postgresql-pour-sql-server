-- ci: skip (four sessions: play it two seconds after 04d-reader.sql, see scene.sh)
-- Clip 3.4, session C: a plain SELECT, which does not conflict with A, waits behind B.
\timing on
select sessionid, prix from outils.m03_session where sessionid = 40;
\timing off
