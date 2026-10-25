-- ci: skip (three sessions: play it one second after 04a-worker.sql, see scene.sh)
-- Clip V3.4, session B: the same worker query takes the next five rows, without waiting.
-- Then NOWAIT on the rows A holds, then the plain FOR UPDATE that waits for A.
set application_name = 'worker B';
begin;
update outils.mv3_convocation c
set status = 'sending', worker = 'B'
from (select inscriptionid
      from outils.mv3_convocation
      where status = 'to send'
      order by inscriptionid
      limit 5
      for update skip locked) as next
where c.inscriptionid = next.inscriptionid
returning c.inscriptionid, c.worker;
select pg_sleep(2);                       -- C looks at the locks meanwhile
rollback;

\set ON_ERROR_STOP off
begin;
select inscriptionid from outils.mv3_convocation
where status = 'to send' order by inscriptionid limit 5
for update nowait;
\echo SQLSTATE :SQLSTATE
rollback;
\set ON_ERROR_STOP on

-- Without SKIP LOCKED nor NOWAIT, B waits for A, then reads the rows again.
\timing on
begin;
select inscriptionid, status from outils.mv3_convocation
where status = 'to send' order by inscriptionid limit 5
for update;
rollback;
\timing off
