-- ci: skip (changes data in the throwaway instance pgd3-source of 04-pitr.sh)
-- Clip D3.4: a legitimate change, the moment to go back to, then the mistake.
-- 04-pitr.sh runs it with psql -At and reads the recovery target on the line "target".
\set QUIET on
select 'avg price before: ' || round(avg(prix), 2) from stage.session where datedebut >= '2020-01-01';
update stage.session set prix = prix * 1.05 where datedebut >= '2020-01-01';
select 'avg price after:  ' || round(avg(prix), 2) from stage.session where datedebut >= '2020-01-01';
select pg_sleep(1) \g /dev/null
select 'target ' || now();
select pg_sleep(1) \g /dev/null
delete from inscription.suivifacture;          -- no where clause
select 'suivifacture rows left: ' || count(*) from inscription.suivifacture;
