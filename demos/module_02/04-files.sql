-- Clip 2.4: the data directory. Lab database, psql. 04-files.sh lists the same files.
select current_setting('data_directory') as pgdata;

-- base/<oid of the database>: one directory per database.
select oid, datname
from pg_database
order by oid;

-- One file per table and per index, named after its relfilenode.
select c.oid, c.relfilenode, c.relname, pg_relation_filepath(c.oid) as file
from pg_class as c
where c.oid in ('stage.session'::regclass, 'stage.pk_sessionstage'::regclass);

-- The forks of a table: main (the rows), fsm (free space map), vm (visibility map).
select fork, pg_size_pretty(pg_relation_size('stage.session', fork)) as size
from unnest(array['main', 'fsm', 'vm']) as fork;

-- The file name is not the OID: TRUNCATE gives the table a new, empty file.
create table outils.m02_copy as select * from stage.session;
select oid, relfilenode, pg_relation_filepath('outils.m02_copy') as file
from pg_class where oid = 'outils.m02_copy'::regclass;
truncate outils.m02_copy;
select oid, relfilenode, pg_relation_filepath('outils.m02_copy') as file
from pg_class where oid = 'outils.m02_copy'::regclass;
drop table outils.m02_copy;
