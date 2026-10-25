-- Module D2 exercise, solution. Lab database, psql, after 1-start.sql.
-- 3-check.sql verifies it, 4-cleanup.sql removes everything it grants.

-- A group for what both roles read: the catalog of sessions and the reference tables.
create role md2x_catalogue;
grant usage on schema stage, reference to md2x_catalogue;
grant select on all tables in schema stage, reference to md2x_catalogue;
grant md2x_catalogue to md2x_app, md2x_analyste;

-- The application: enrol and update an enrolment, nothing else. RETURNING needs SELECT on
-- the columns it returns.
grant usage on schema inscription to md2x_app;
grant insert on inscription.inscription to md2x_app;
grant update (present, dateannulation) on inscription.inscription to md2x_app;
grant select (inscriptionid, sessionid, contactid) on inscription.inscription to md2x_app;

-- The analyst: every enrolment table, today and tomorrow, and the contacts without their
-- personal data.
grant usage on schema inscription, contact to md2x_analyste;
grant select on all tables in schema inscription to md2x_analyste;
alter default privileges for role postgres in schema inscription
    grant select on tables to md2x_analyste;
grant select (contactid, titre, nom, prenom, societeid) on contact.contact to md2x_analyste;

-- What each role received, table by table.
select grantee, table_schema, count(*) as tables, string_agg(distinct privilege_type, ', ') as privileges
from information_schema.role_table_grants
where grantee like 'md2x\_%'
group by grantee, table_schema
order by grantee, table_schema;

-- Column privileges are listed under the table, in \dp.
\dp inscription.inscription
\dp contact.contact
