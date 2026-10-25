-- ci: skip (two sessions: play it with 03d-overbook-b.sql, see scene.sh)
-- Clip 3.3, session A. Session 41 has 11 enrollments for 12 seats. Each session counts,
-- then enrolls one more trainee if a seat is left: first in repeatable read, then in
-- serializable. Start session B (03d-overbook-b.sql) one second after this one.
delete from outils.m03_inscription where inscriptionid >= 900000;

-- 1. Repeatable read.
begin transaction isolation level repeatable read;
select count(*) as enrolled from outils.m03_inscription where sessionid = 41;
select pg_sleep(2);
insert into outils.m03_inscription (inscriptionid, sessionid)
select 900001, 41
where (select count(*) from outils.m03_inscription where sessionid = 41) < 12;
commit;

select pg_sleep(3);                       -- B commits meanwhile
select count(*) as enrolled from outils.m03_inscription where sessionid = 41;
delete from outils.m03_inscription where inscriptionid >= 900000;

-- 2. Serializable: the same transaction.
begin transaction isolation level serializable;
select count(*) as enrolled from outils.m03_inscription where sessionid = 41;
select pg_sleep(2);
insert into outils.m03_inscription (inscriptionid, sessionid)
select 900001, 41
where (select count(*) from outils.m03_inscription where sessionid = 41) < 12;
commit;

select pg_sleep(3);
select count(*) as enrolled from outils.m03_inscription where sessionid = 41;
delete from outils.m03_inscription where inscriptionid >= 900000;
