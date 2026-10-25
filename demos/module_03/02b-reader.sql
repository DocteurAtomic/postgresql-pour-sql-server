-- ci: skip (two sessions: play it after 02a-writer.sql, see scene.sh)
-- Clip 3.2, session B, the reader, in read committed (the default). Lab database, psql.
-- Reads session 40 while A holds its uncommitted UPDATE, then again after A's COMMIT,
-- in the same transaction.
show transaction_isolation;

begin;
\timing on
select sessionid, prix from outils.m03_session where sessionid = 40;
\timing off
select pg_sleep(7);
select sessionid, prix from outils.m03_session where sessionid = 40;
commit;

-- No NOLOCK hint: the T-SQL table hint is a syntax error here.
\set ON_ERROR_STOP off
select sessionid, prix from outils.m03_session with (nolock) where sessionid = 40;
\set ON_ERROR_STOP on
