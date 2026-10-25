-- Clip 5.2: the access paths to a table. Lab database, psql, after 00-setup.sql.
-- outils.m05_facture is a copy of inscription.facture, primary key on facturecd,
-- index on datefacture, autovacuum off, never vacuumed: its visibility map is empty.

-- Seq Scan: two thirds of the rows, no index on the column.
explain analyze
select facturecd, montantttc from outils.m05_facture where montantttc > 5000;

-- Index Scan: one row by its key. The index gives the address, the table the row.
explain analyze
select facturecd, datefacture, montantttc from outils.m05_facture where facturecd = 'F000002';

-- Bitmap Index Scan then Bitmap Heap Scan: one month of invoices.
explain analyze
select facturecd, datefacture, montantttc
from outils.m05_facture
where datefacture between date '2011-03-01' and date '2011-03-31';

-- Index Only Scan: only the indexed column. The visibility map is empty,
-- every row is checked in the table (Heap Fetches).
select relpages, relallvisible from pg_class where oid = 'outils.m05_facture'::regclass;
explain analyze
select datefacture
from outils.m05_facture
where datefacture between date '2011-03-01' and date '2011-03-31';

-- VACUUM sets the visibility map: the same query no longer reads the table.
vacuum outils.m05_facture;
select relpages, relallvisible from pg_class where oid = 'outils.m05_facture'::regclass;
explain analyze
select datefacture
from outils.m05_facture
where datefacture between date '2011-03-01' and date '2011-03-31';

-- An UPDATE clears the bit of every page it writes to: those rows are checked again.
update outils.m05_facture set relance = relance
where datefacture between date '2011-03-14' and date '2011-03-15';
explain analyze
select datefacture
from outils.m05_facture
where datefacture between date '2011-03-01' and date '2011-03-31';
