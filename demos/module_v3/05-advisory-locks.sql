-- Clip V3.5: advisory locks at session level and at transaction level, as pg_locks shows
-- them. Lab database, psql, one session. The key (1, 41) stands for "invoicing of session 41":
-- its meaning is the application's, PostgreSQL only compares the numbers.

-- 1. Session level: the lock survives COMMIT and ROLLBACK, and requests stack.
begin;
select pg_advisory_lock(1, 41);
select pg_advisory_lock(1, 41);           -- the same session: granted again, counted twice
rollback;
select locktype, classid, objid, objsubid, mode, granted
from pg_locks where locktype = 'advisory' and pid = pg_backend_pid();
select pg_advisory_unlock(1, 41) as first_unlock, pg_advisory_unlock(1, 41) as second_unlock;
select pg_advisory_unlock(1, 41) as third_unlock;

-- 2. Transaction level: released by COMMIT or ROLLBACK, no unlock function.
begin;
select pg_advisory_xact_lock(1, 41);
select pg_advisory_xact_lock(4100000000);  -- a single bigint key
select classid, objid, objsubid, mode
from pg_locks where locktype = 'advisory' and pid = pg_backend_pid() order by objsubid;
commit;
select count(*) as advisory_locks_left
from pg_locks where locktype = 'advisory' and pid = pg_backend_pid();
