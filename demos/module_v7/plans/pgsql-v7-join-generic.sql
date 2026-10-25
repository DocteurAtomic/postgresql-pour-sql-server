-- Captured by hand, in one session: the generic plan of the exercise's prepared statement,
-- executed with the value 0.
set plan_cache_mode = force_generic_plan;
prepare enrolled_by_reminder(smallint) as
select count(*) as enrollments, count(distinct i.contactid) as contacts
from inscription.facture f
join inscription.inscriptionfacture fi on fi.facturecd = f.facturecd
join inscription.inscription i on i.inscriptionid = fi.inscriptionid
where f.relance = $1;
explain (analyze, buffers, format json) execute enrolled_by_reminder(0);
