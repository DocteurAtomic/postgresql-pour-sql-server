-- ci: skip (two sessions: run with 04-lock-holder.sql, see 04-server-log.sh)
-- Clip D1.4, session 2: waits for the row lock, longer than deadlock_timeout (1 s).
update d1_account set balance = balance - 1 where id = 1;
