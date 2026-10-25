-- Clip 5.3: joins, aggregates, sorts and parallelism. Lab database, psql.

-- Hash Join: the enrollments of the 2020 sessions. inscription.sessionid has no index
-- in the port, the 30 436 enrollments are read once and probed in a hash of the sessions.
explain analyze
select s.sessionid, count(*) as enrollments
from stage.session as s
join inscription.inscription as i on i.sessionid = s.sessionid
where s.datedebut >= date '2020-01-01'
group by s.sessionid;

-- Merge Join: two inputs already sorted on the join key, by their primary keys.
explain analyze
select i.inscriptionid, f.facturecd
from inscription.inscription as i
join inscription.inscriptionfacture as f on f.inscriptionid = i.inscriptionid;
-- Why the merge stops early: no invoice line after this enrollment.
select max(f.inscriptionid) as last_invoiced,
       (select count(*) from inscription.inscription as i
        where i.inscriptionid > max(f.inscriptionid)) as enrollments_after
from inscription.inscriptionfacture as f;

-- GroupAggregate: the rows arrive sorted on the group key, from the index.
explain analyze
select relance, count(*) from inscription.facture group by relance;

-- Sort: the ten largest invoices, a top-N sort that keeps ten rows in memory.
explain analyze
select facturecd, montantttc from inscription.facture order by montantttc desc limit 10;

-- Parallelism: 300 000 prospects counted by two workers and the leader, then
-- grouped by city, where Gather Merge keeps the order of the sorted partial groups.
explain analyze
select count(email) from contact.prospectus;

explain analyze
select ville, count(*) from contact.prospectus group by ville;
