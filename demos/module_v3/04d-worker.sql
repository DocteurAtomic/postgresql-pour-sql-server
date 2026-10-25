-- ci: skip (three sessions: play it with 04e-ddl.sql and 04f-worker.sql, see scene.sh)
-- Clip V3.4, session A: a worker holds its five notices six seconds.
set application_name = 'worker A';
update outils.mv3_convocation set status = 'to send', worker = null;
begin;
update outils.mv3_convocation c
set status = 'sending', worker = 'A'
from (select inscriptionid from outils.mv3_convocation
      where status = 'to send' order by inscriptionid limit 5
      for update skip locked) as next
where c.inscriptionid = next.inscriptionid;
select pg_sleep(6);
commit;
