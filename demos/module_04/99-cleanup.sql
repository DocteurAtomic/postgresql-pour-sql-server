-- Module 4, cleanup. Lab database, psql. Leaves the database as it was restored.
drop table if exists outils.m04_case;
drop table if exists outils.m04_long;
drop table if exists outils.m04_contact;
drop table if exists outils.m04_ident;
drop table if exists outils.m04_serial;
drop table if exists outils.m04_uuid_v4;
drop table if exists outils.m04_uuid_v7;
drop collation if exists outils.m04_ci;
drop collation if exists outils.m04_ci_ai;
drop extension if exists pgstattuple;
drop extension if exists citext;

select extname from pg_extension order by extname;
