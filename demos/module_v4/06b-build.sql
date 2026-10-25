-- ci: skip (three sessions: play it one second after 06a-reader.sql, see scene.sh)
-- Clip V4.6, session B: the concurrent build, timed. It ends when A ends.
\timing on
create index concurrently mv4_inscription_sessionid on outils.mv4_inscription (sessionid);
\timing off
select indisvalid from pg_index where indexrelid = 'outils.mv4_inscription_sessionid'::regclass;
