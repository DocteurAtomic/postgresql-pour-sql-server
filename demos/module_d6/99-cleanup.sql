-- Module D6, cleanup. Lab database, psql. The module created nothing in the lab; the
-- throwaway containers of its .sh scripts remove themselves with their volumes and the
-- network pgd6-net. This checks that the lab has no slot, no publication and no
-- subscription left.
select (select count(*) from pg_replication_slots) as slots,
       (select count(*) from pg_publication) as publications,
       (select count(*) from pg_subscription) as subscriptions;
