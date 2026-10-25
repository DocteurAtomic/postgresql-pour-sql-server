-- Module 2, cleanup. Lab database, psql. Leaves the database as it was restored.
drop server if exists m02_loopback cascade;      -- the foreign server of 05, its user mapping and foreign tables
drop schema if exists m02_remote cascade;
drop table if exists outils.m02_wal;
drop table if exists outils.m02_copy;
drop database if exists m02_demo;
drop extension if exists postgres_fdw;
drop extension if exists pg_walinspect;
drop extension if exists pg_buffercache;

select extname from pg_extension order by extname;
