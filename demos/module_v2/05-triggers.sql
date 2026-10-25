-- Clip V2.5: triggers. Lab database, psql.
-- Some statements fail on purpose: ON_ERROR_STOP is off around them.
-- Works on copies (outils.mv2_contact, outils.mv2_inscription), dropped at the end.
create table outils.mv2_contact as
select contactid, nom, prenom, email
from contact.contact
where contactid <= 1000;
alter table outils.mv2_contact add primary key (contactid);

-- Contact.atr_Contact_CheckEmail, ported: a trigger function, then the trigger.
-- BEFORE ... FOR EACH ROW: NEW is the row about to be written, and can be changed.
create function outils.mv2_contact_check_email()
returns trigger
language plpgsql
as $$
begin
    new.email := lower(trim(new.email));
    if new.email not like '%_@_%._%' then
        raise exception 'invalid email for contact %: %', new.contactid, new.email
            using errcode = 'check_violation';
    end if;
    return new;
end
$$;
create trigger mv2_contact_check_email
before insert or update of email on outils.mv2_contact
for each row
execute function outils.mv2_contact_check_email();

-- The trigger runs for each row: the invalid second row stops the whole UPDATE.
\set ON_ERROR_STOP off
update outils.mv2_contact
set email = case contactid when 1 then 'first@contact.example' else 'not-an-email' end
where contactid in (1, 2);
\set ON_ERROR_STOP on
select contactid, email from outils.mv2_contact where contactid in (1, 2) order by contactid;

-- The trigger changed the value written.
update outils.mv2_contact set email = '  J.Garcia@Contact.EXAMPLE ' where contactid = 1;
select contactid, email from outils.mv2_contact where contactid = 1;

-- RETURN NULL in a BEFORE trigger skips the row, without an error.
create table outils.mv2_inscription (
    inscriptionid integer generated always as identity primary key,
    sessionid integer not null,
    contactid integer not null);
create function outils.mv2_inscription_skip_duplicate()
returns trigger
language plpgsql
as $$
begin
    if exists (select 1 from outils.mv2_inscription
               where sessionid = new.sessionid and contactid = new.contactid) then
        return null;
    end if;
    return new;
end
$$;
create trigger mv2_inscription_skip_duplicate
before insert on outils.mv2_inscription
for each row
execute function outils.mv2_inscription_skip_duplicate();
insert into outils.mv2_inscription (sessionid, contactid) values (45, 121);
insert into outils.mv2_inscription (sessionid, contactid) values (45, 121);
select inscriptionid, sessionid, contactid from outils.mv2_inscription;

-- A statement trigger with transition tables, named as in SQL Server.
create table outils.mv2_email_audit (
    changed_at timestamptz not null default now(),
    contacts integer not null,
    emails_changed integer not null);
create function outils.mv2_contact_audit()
returns trigger
language plpgsql
as $$
begin
    insert into outils.mv2_email_audit (contacts, emails_changed)
    select count(*), count(*) filter (where i.email is distinct from d.email)
    from inserted as i
    join deleted as d on d.contactid = i.contactid;
    return null;
end
$$;
create trigger mv2_contact_audit
after update on outils.mv2_contact
referencing old table as deleted new table as inserted
for each statement
execute function outils.mv2_contact_audit();
update outils.mv2_contact
set email = 'c' || contactid || '@contact.example'
where contactid between 10 and 14 and email is not null;
update outils.mv2_contact set nom = upper(nom) where contactid between 10 and 14;
select contacts, emails_changed from outils.mv2_email_audit order by changed_at;

-- INSTEAD OF exists only on views.
\set ON_ERROR_STOP off
create trigger mv2_contact_instead
instead of update on outils.mv2_contact
for each row
execute function outils.mv2_contact_check_email();
\set ON_ERROR_STOP on

drop table outils.mv2_email_audit;
drop table outils.mv2_inscription;
drop table outils.mv2_contact;
drop function outils.mv2_contact_audit();
drop function outils.mv2_inscription_skip_duplicate();
drop function outils.mv2_contact_check_email();
