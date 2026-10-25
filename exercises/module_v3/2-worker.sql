-- Module V3 exercise, solution: the worker procedure. Lab database, psql.
--   docker compose exec db psql -U postgres -d pachadataformation -f /exercises/module_v3/2-worker.sql
-- It loops over batches: take p_batch pending invoices, mark them invoiced, log them, wait
-- 0.1 s (the work), commit, until the queue is empty. With p_skip_locked false, it reads
-- the batch without locking it, then updates it: the version to compare with.
create or replace procedure outils.mv3_invoice_worker(
    p_worker text, p_batch int default 10, p_skip_locked boolean default true)
language plpgsql
as $$
declare
    v_done int;
    v_batches int := 0;
begin
    loop
        if p_skip_locked then
            with next as (
                select facturecd from outils.mv3_invoice_queue
                where status = 'pending'
                order by facturecd
                limit p_batch
                for update skip locked),
            done as (
                update outils.mv3_invoice_queue q
                set status = 'invoiced', worker = p_worker, datefacture = current_date
                from next
                where q.facturecd = next.facturecd
                returning q.facturecd)
            insert into outils.mv3_invoice_log (facturecd, worker)
            select facturecd, p_worker from done;
        else
            with next as (
                select facturecd from outils.mv3_invoice_queue
                where status = 'pending'
                order by facturecd
                limit p_batch),
            done as (
                update outils.mv3_invoice_queue q
                set status = 'invoiced', worker = p_worker, datefacture = current_date
                from next
                where q.facturecd = next.facturecd
                returning q.facturecd)
            insert into outils.mv3_invoice_log (facturecd, worker)
            select facturecd, p_worker from done;
        end if;
        get diagnostics v_done = row_count;
        exit when v_done = 0;
        v_batches := v_batches + 1;
        perform pg_sleep(0.1);
        commit;
    end loop;
    raise notice 'worker %: % batches', p_worker, v_batches;
end;
$$;
