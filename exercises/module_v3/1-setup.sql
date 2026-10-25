-- Module V3 exercise, starting point. Lab database, psql.
--   docker compose exec db psql -U postgres -d pachadataformation -f /exercises/module_v3/1-setup.sql
-- The queue: the 105 invoices of inscription.facture that have no invoice date yet, copied
-- in outils.mv3_invoice_queue, and the log a worker writes for each invoice it processes.
-- 4-cleanup.sql drops both tables and the procedure of the solution.
drop table if exists outils.mv3_invoice_log;
drop table if exists outils.mv3_invoice_queue;
create table outils.mv3_invoice_queue as
select facturecd, montantttc, 'pending'::text as status, null::text as worker,
       null::date as datefacture
from inscription.facture
where datefacture is null;
alter table outils.mv3_invoice_queue add primary key (facturecd);
create table outils.mv3_invoice_log (
    facturecd   varchar(50) not null,
    worker      text not null,
    logged_at   timestamptz not null default clock_timestamp()
);
select count(*) as pending_invoices, sum(montantttc) as total_ttc
from outils.mv3_invoice_queue;
