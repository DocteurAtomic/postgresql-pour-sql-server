-- ci: skip (two sessions: run with 04-lock-waiter.sql, see 04-server-log.sh)
-- Clip D1.4, session 1: holds a row lock for three seconds.
begin;
update d1_account set balance = balance + 1 where id = 1;
select pg_sleep(3);
commit;
