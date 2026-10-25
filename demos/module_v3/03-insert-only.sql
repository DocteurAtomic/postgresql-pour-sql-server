-- ci: skip (the wrong retry, played by 03-retry.sh)
-- Clip V3.3: the wrong retry. It replays only the INSERT, with the decision taken by the
-- failed attempt, instead of the whole transaction. Variables: app, id.
\set ON_ERROR_STOP on
\set VERBOSITY verbose
\set SHOW_CONTEXT never
begin isolation level serializable;
insert into outils.mv3_inscription (inscriptionid, sessionid) values (:id, 41);
\echo :app inserts :id again, without counting
commit;
\echo :app commits
