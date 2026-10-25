-- ci: skip (reads an instance of the exercise, pgd3-exercise or pgd3-exercise-restore)
-- Module D3 exercise: the three changes of the day, as this instance sees them.
select (select count(*) from stage.session where prix = 0) as sessions_at_zero,
       (select round(avg(prix), 2) from stage.session) as avg_price,
       (select sum(relance) from inscription.facture) as total_relance,
       (select count(*) from inscription.facture where daterelance = current_date) as reminded_today;
