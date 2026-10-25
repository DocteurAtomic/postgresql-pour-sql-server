-- Captured by hand, in one session: the generic plan of the prepared statement,
-- executed with the value 0.
set plan_cache_mode = force_generic_plan;
prepare unpaid(smallint) as
select count(*) as invoices, sum(montantttc) as amount
from inscription.facture where relance = $1;
explain (analyze, buffers, format json) execute unpaid(0);
