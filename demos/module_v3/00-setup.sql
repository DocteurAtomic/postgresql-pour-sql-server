-- Module V3, setup. Lab database (pachadataformation), psql:
--   docker compose exec db psql -U postgres -d pachadataformation -f /demos/module_v3/00-setup.sql
-- The module needs no extension. It creates its demo tables in the outils schema, copies of
-- inscription.inscription; 99-cleanup.sql drops them.

-- The enrollments of the retry loop (clip V3.3): session 41 has 11 enrollments, 12 seats.
drop table if exists outils.mv3_inscription;
create table outils.mv3_inscription as
select inscriptionid, sessionid, contactid
from inscription.inscription;
alter table outils.mv3_inscription add primary key (inscriptionid);
create index on outils.mv3_inscription (sessionid);

-- The queue of the workers (clip V3.4): one notice to send per enrollment in a 2020
-- session whose notice was not sent yet.
drop table if exists outils.mv3_convocation;
create table outils.mv3_convocation as
select i.inscriptionid, i.sessionid, 'to send'::text as status, null::text as worker
from inscription.inscription i
join stage.session s on s.sessionid = i.sessionid
where s.datedebut >= date '2020-01-01' and not i.convocationenvoyee;
alter table outils.mv3_convocation add primary key (inscriptionid);
vacuum analyze outils.mv3_inscription, outils.mv3_convocation;

select relname, reltuples::bigint as rows
from pg_class
where oid in ('outils.mv3_inscription'::regclass, 'outils.mv3_convocation'::regclass)
order by relname;
