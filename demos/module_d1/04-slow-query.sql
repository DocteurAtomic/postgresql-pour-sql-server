-- ci: skip (meant to be read in the server log of 04-server-log.sh)
-- Clip D1.4: a statement of 300 ms, above log_min_duration_statement.
select pg_sleep(0.3);
