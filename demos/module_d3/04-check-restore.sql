-- ci: skip (reads the instances of 04-pitr.sh, restored or source)
-- Clip D3.4: the two changes made after the base backup, as this instance sees them.
select (select count(*) from inscription.suivifacture) as suivifacture,
       (select round(avg(prix), 2) from stage.session
         where datedebut >= '2020-01-01') as avg_price_since_2020;
