-- Clip V7.5: auto_explain in one session, for the plan of a query that runs inside a
-- function. Lab database, psql. LOAD needs a superuser; the settings last for the session.
-- auto_explain.log_level = notice sends the plans to the client instead of the server log.

-- EXPLAIN of the call shows the call, not the query inside the function.
explain (analyze, costs off, timing off, summary off) select outils.mv7_enrolled(0::smallint);

load 'auto_explain';
set auto_explain.log_min_duration = 0;        -- every statement; '250ms' in a real session
set auto_explain.log_analyze = on;
set auto_explain.log_timing = off;
set auto_explain.log_nested_statements = on;  -- the statements inside functions too
set auto_explain.log_level = notice;

-- First call: a custom plan, built for 0.
select outils.mv7_enrolled(0::smallint);

-- Calls 2 to 5, plans not shown (debug1 stays below client_min_messages).
set auto_explain.log_level = debug1;
\o /dev/null
select outils.mv7_enrolled(0::smallint);
select outils.mv7_enrolled(0::smallint);
select outils.mv7_enrolled(0::smallint);
select outils.mv7_enrolled(0::smallint);
\o

-- Sixth call: PL/pgSQL keeps its plans like a prepared statement, and the generic plan wins.
set auto_explain.log_level = notice;
select outils.mv7_enrolled(0::smallint);
