-- ci: skip (three sessions: play it one second after 04e-ddl.sql, see scene.sh)
-- Clip V3.4, session C: a second worker with SKIP LOCKED. SKIP LOCKED skips rows, not the
-- table lock: C waits behind the ALTER TABLE, which waits behind A.
set application_name = 'worker C';
\timing on
begin;
update outils.mv3_convocation c
set status = 'sending', worker = 'C'
from (select inscriptionid from outils.mv3_convocation
      where status = 'to send' order by inscriptionid limit 5
      for update skip locked) as next
where c.inscriptionid = next.inscriptionid;
rollback;
\timing off
