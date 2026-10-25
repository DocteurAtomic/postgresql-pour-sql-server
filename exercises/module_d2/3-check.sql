-- Module D2 exercise, checks. Lab database, psql, after 2-solution.sql. Each role tries
-- what it must be able to do and what it must not; the refusals are expected, so
-- ON_ERROR_STOP is off. The enrolment is rolled back, and the identity sequence, which a
-- rollback does not undo, is put back where it was.
select last_value as seq_last, is_called as seq_called
from inscription.inscription_inscriptionid_seq \gset
\set ON_ERROR_STOP off

set role md2x_app;
select count(*) as sessions from stage.session;
begin;
insert into inscription.inscription (sessionid, contactid) values (1, 1)
returning inscriptionid as new_id \gset
update inscription.inscription set present = true where inscriptionid = :new_id;
rollback;
delete from inscription.inscription where inscriptionid = 1;
select count(*) from contact.contact;
select count(*) from inscription.facture;
reset role;

set role md2x_analyste;
select count(*) as factures from inscription.facture;
select nom, prenom from contact.contact where contactid = 1;
select email from contact.contact where contactid = 1;
reset role;

-- A table created later in inscription: the default privileges cover it.
create table inscription.md2x_relance (inscriptionid int, daterelance date);
set role md2x_analyste;
select count(*) as relances from inscription.md2x_relance;
reset role;
drop table inscription.md2x_relance;
select setval('inscription.inscription_inscriptionid_seq', :seq_last, :'seq_called');

\set ON_ERROR_STOP on
