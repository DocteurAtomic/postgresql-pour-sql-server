-- ci: skip (three sessions: play it one second after 04b-worker.sql, see scene.sh)
-- Clip V3.4, session C: the table locks of the two workers. FOR UPDATE takes ROW SHARE on
-- the table, SKIP LOCKED or not; the UPDATE adds ROW EXCLUSIVE.
select a.application_name, l.locktype, l.mode, l.granted, count(*) as locks
from pg_locks l
join pg_stat_activity a on a.pid = l.pid
where a.application_name like 'worker%'
  and l.relation = 'outils.mv3_convocation'::regclass
group by a.application_name, l.locktype, l.mode, l.granted
order by a.application_name, l.mode;
