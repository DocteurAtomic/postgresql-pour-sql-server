-- Module V2, cleanup. Lab database, psql. Leaves the database as it was restored:
-- drops every object of the module that an interrupted run left behind.
drop table if exists outils.mv2_inscription;
drop table if exists outils.mv2_log;
drop table if exists outils.mv2_cost;
drop table if exists outils.mv2_email_audit;
drop table if exists outils.mv2_contact;

-- The functions and procedures named mv2_ in the outils schema.
select format('drop %s %s',
              case p.prokind when 'p' then 'procedure' else 'function' end,
              p.oid::regprocedure)
from pg_proc as p
where p.pronamespace = 'outils'::regnamespace
  and p.proname like 'mv2\_%'
\gexec

select count(*) as mv2_objects_left
from pg_class
where relnamespace = 'outils'::regnamespace and relname like 'mv2\_%';
select count(*) as mv2_routines_left
from pg_proc
where pronamespace = 'outils'::regnamespace and proname like 'mv2\_%';
