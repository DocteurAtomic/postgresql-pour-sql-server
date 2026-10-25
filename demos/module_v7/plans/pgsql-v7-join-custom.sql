-- The custom plan of the exercise's query for the value 0, the plan the value gets when it is
-- written in the query. Captured by capturer-plan-pg.sh.
select count(*) as enrollments, count(distinct i.contactid) as contacts
from inscription.facture f
join inscription.inscriptionfacture fi on fi.facturecd = f.facturecd
join inscription.inscription i on i.inscriptionid = fi.inscriptionid
where f.relance = 0
