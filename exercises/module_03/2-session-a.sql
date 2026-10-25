-- ci: skip (two sessions: play it with 2-session-b.sql)
-- Module 3 exercise, solution of question 1, session A. From the root of the repository:
--   ./demos/module_03/scene.sh exercises/module_03/2-session-a.sql exercises/module_03/2-session-b.sql
-- A reads the discount of enrollment 3 in repeatable read, then raises it by 5.
update outils.m03_exercise set remise = 0 where inscriptionid = 3;   -- known start value

begin transaction isolation level repeatable read;
select inscriptionid, remise from outils.m03_exercise where inscriptionid = 3;
select pg_sleep(2);
update outils.m03_exercise set remise = remise + 5 where inscriptionid = 3;
select pg_sleep(2);
commit;
