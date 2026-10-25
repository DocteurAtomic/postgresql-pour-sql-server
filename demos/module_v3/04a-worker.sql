-- ci: skip (three sessions: play it with 04b-worker.sql and 04c-observer.sql, see scene.sh)
-- Clip V3.4, session A: a worker takes the next five notices to send, skipping the rows
-- other workers hold, keeps them six seconds (the sending), then marks them sent.
set application_name = 'worker A';
update outils.mv3_convocation set status = 'to send', worker = null;
begin;
update outils.mv3_convocation c
set status = 'sending', worker = 'A'
from (select inscriptionid
      from outils.mv3_convocation
      where status = 'to send'
      order by inscriptionid
      limit 5
      for update skip locked) as next
where c.inscriptionid = next.inscriptionid
returning c.inscriptionid, c.worker;
select pg_sleep(6);
update outils.mv3_convocation set status = 'sent' where worker = 'A' and status = 'sending';
commit;
