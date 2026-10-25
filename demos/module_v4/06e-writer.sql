-- ci: skip (two sessions: play it one second after 06d-plain-build.sql, see scene.sh)
-- Clip V4.6, session B: the same INSERT waits for the end of A.
\timing on
insert into outils.mv4_inscription (inscriptionid, sessionid, contactid, datecreation)
values (99000001, 40, 1203, timestamp '2026-07-21 09:00');
\timing off
delete from outils.mv4_inscription where inscriptionid = 99000001;
