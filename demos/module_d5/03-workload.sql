-- ci: skip (read by 03-cumulative-stats.sh in the container pgd5-stats)
-- Clip D5.3: a small workload: lookups by key, full scans, a sort that spills to disk,
-- and an update rolled back.
select count(*) from inscription.facture where facturecd = 'F0001' \g /dev/null
select count(*) from inscription.facture where facturecd = 'F0002' \g /dev/null
select count(*) from inscription.facture where facturecd = 'F0003' \g /dev/null
select sum(montantht) from inscription.facture \g /dev/null
select sum(montantttc) from inscription.facture \g /dev/null
set work_mem = '64kB';
select facturecd from inscription.facture order by montantttc desc, facturecd \g /dev/null
reset work_mem;
begin;
update inscription.facture set relance = relance where relance = 2;
rollback;
