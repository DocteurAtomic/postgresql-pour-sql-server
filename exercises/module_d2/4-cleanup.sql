-- Module D2 exercise, cleanup. Lab database, psql. Drops the roles of the exercise, their
-- privileges and the default privileges granted to them.
alter default privileges for role postgres in schema inscription
    revoke select on tables from md2x_analyste;
drop owned by md2x_app, md2x_analyste, md2x_catalogue;
drop role md2x_app, md2x_analyste, md2x_catalogue;

select count(*) as md2x_roles from pg_roles where rolname like 'md2x\_%';
