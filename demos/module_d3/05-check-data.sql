-- ci: skip (reads the instances of 05-incremental.sh, source or restored)
-- Clip D3.5: two figures that the changes of the script move, to compare both instances.
select (select round(avg(prix), 2) from stage.session) as avg_price,
       (select sum(relance) from inscription.facture) as total_relance;
