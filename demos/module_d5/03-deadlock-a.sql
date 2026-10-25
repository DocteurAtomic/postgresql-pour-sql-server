-- ci: skip (read by 03-cumulative-stats.sh in the container pgd5-stats)
-- Clip D5.3, session A of a deadlock: invoice 1, then invoice 2.
begin;
update inscription.facture set relance = relance where facturecd = (select min(facturecd) from inscription.facture);
select pg_sleep(1);
update inscription.facture set relance = relance where facturecd = (select max(facturecd) from inscription.facture);
commit;
