-- Clip D2.4: row-level security on outils.md2_session, the copy of stage.session made by
-- 00-setup.sql. Lab database, psql. Run after 03-privileges.sql, which gave md2_lecture
-- SELECT on the tables of outils. The policy is dropped with the table by 99-cleanup.sql.

-- Row security on, no policy yet: default deny for everybody but the owner.
alter table outils.md2_session enable row level security;
select count(*) as rows_for_postgres from outils.md2_session;
set role md2_app;
select count(*) as rows_for_md2_app from outils.md2_session;
reset role;
-- pg_read_all_data does not bypass row security either.
set role md2_analyste;
select count(*) as rows_for_md2_analyste from outils.md2_session;
reset role;

-- A policy: a trainer sees his sessions. The application sets md2.formateurid, as it would
-- call sp_set_session_context in SQL Server.
create policy md2_formateur on outils.md2_session
    for select to md2_lecture
    using (formateurid = current_setting('md2.formateurid', true)::int);

set role md2_app;
select count(*) as rows_no_setting from outils.md2_session;
set md2.formateurid = '2';
select count(*) as rows_formateur_2 from outils.md2_session;
-- Nothing stops the session from changing the setting: it is not a secret.
set md2.formateurid = '3';
select count(*) as rows_formateur_3 from outils.md2_session;
-- The policy is added to the query as a filter.
explain (costs off) select count(*) from outils.md2_session;
reset md2.formateurid;
reset role;

-- The owner bypasses its own policies, unless FORCE ROW LEVEL SECURITY.
alter table outils.md2_session owner to md2_app;
set role md2_app;
set md2.formateurid = '2';
select count(*) as rows_owner from outils.md2_session;
reset role;
alter table outils.md2_session force row level security;
-- The policy is "to md2_lecture": the owner, a member, now goes through it.
set role md2_app;
select count(*) as rows_owner_forced from outils.md2_session;
reset md2.formateurid;
reset role;
-- A superuser bypasses everything, FORCE included.
select count(*) as rows_superuser from outils.md2_session;

select relname, relrowsecurity, relforcerowsecurity, relowner::regrole as owner
from pg_class
where relname = 'md2_session';
select policyname, roles, cmd, qual
from pg_policies
where tablename = 'md2_session';
