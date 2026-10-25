-- ci: skip (one attempt of the application's transaction, played by 03-retry.sh)
-- Clip V3.3: enroll one trainee in session 41 (12 seats) if a seat is left, in serializable.
-- The decision is made on the client, as an application does: psql reads the count with
-- \gset and decides with \if. Variables: app (name), id (inscriptionid), pause (seconds).
\set ON_ERROR_STOP on
\set VERBOSITY verbose
\set SHOW_CONTEXT never
begin isolation level serializable;
select count(*) as enrolled, count(*) < 12 as seat_left
from outils.mv3_inscription where sessionid = 41 \gset
\echo :app counts :enrolled enrolled
select pg_sleep(:pause) \gset
\if :seat_left
insert into outils.mv3_inscription (inscriptionid, sessionid) values (:id, 41);
\echo :app inserts :id
\else
\echo :app finds the session full
\endif
commit;
\echo :app commits
