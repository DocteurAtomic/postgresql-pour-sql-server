-- Module V2 exercise, solution. Lab database, psql.
-- Ports dbo.Inscrire (sqlserver/1-inscrire.sql) to PL/pgSQL. The procedure writes into
-- outils.mv2_inscription, a copy of inscription.inscription, so that the lab database
-- stays as it was; everything is dropped at the end.
-- Some calls fail on purpose: ON_ERROR_STOP is off around them.

-- The copy, with its own identity: LIKE ... INCLUDING ALL creates a new sequence, which
-- starts at 1 although the copied rows go from 3 to the last identifier: the third insert
-- without an identifier would fail on the primary key. setval moves the sequence.
create table outils.mv2_inscription (like inscription.inscription including all);
insert into outils.mv2_inscription overriding system value
select * from inscription.inscription;
select setval(pg_get_serial_sequence('outils.mv2_inscription', 'inscriptionid'),
              max(inscriptionid)) as last_inscriptionid
from outils.mv2_inscription;

create procedure outils.mv2_inscrire(
    p_contactid integer,
    p_sessionid integer,
    out p_inscriptionid integer,
    out p_listeattente boolean,
    p_remise smallint default 0)
language plpgsql
as $$
declare
    v_places smallint;
    v_inscrits bigint;
begin
    if not exists (select 1 from contact.contact where contactid = p_contactid) then
        raise exception 'Contact inconnu : %', p_contactid
            using errcode = 'foreign_key_violation';
    end if;
    if p_remise not between 0 and 100 then
        raise exception 'La remise doit être comprise entre 0 et 100 : %', p_remise
            using errcode = 'check_violation';
    end if;

    -- No foreign key between the inscriptions and the sessions in the port: the
    -- procedure checks the session itself, and locks its row (UPDLOCK, HOLDLOCK).
    select r.places into v_places
    from stage.session as s
    left join reference.salleformation as r on r.salleformationid = s.salleformationid
    where s.sessionid = p_sessionid
    for update of s;
    if not found then
        raise exception 'Session inconnue : %', p_sessionid
            using errcode = 'foreign_key_violation';
    end if;

    if exists (select 1 from outils.mv2_inscription
               where contactid = p_contactid and sessionid = p_sessionid
                 and dateannulation is null) then
        raise exception 'Contact % déjà inscrit à la session %', p_contactid, p_sessionid
            using errcode = 'unique_violation';
    end if;

    select count(*) into v_inscrits
    from outils.mv2_inscription
    where sessionid = p_sessionid and dateannulation is null and not listeattente;

    -- A session without a room has no limit: v_places is NULL, and so would be the
    -- comparison. The CASE of T-SQL turned NULL into 0; here coalesce does it.
    p_listeattente := coalesce(v_inscrits >= v_places, false);

    insert into outils.mv2_inscription (sessionid, contactid, remise, listeattente)
    values (p_sessionid, p_contactid, p_remise, p_listeattente)
    returning inscriptionid into p_inscriptionid;
end
$$;

-- The same calls as on SQL Server, with the identifiers of the lab.
select min(s.sessionid) as open_session
from stage.session as s
join reference.salleformation as r on r.salleformationid = s.salleformationid
where r.places > (select count(*) from outils.mv2_inscription as i
                  where i.sessionid = s.sessionid and i.dateannulation is null
                    and not i.listeattente) \gset
select min(s.sessionid) as full_session
from stage.session as s
join reference.salleformation as r on r.salleformationid = s.salleformationid
where r.places <= (select count(*) from outils.mv2_inscription as i
                   where i.sessionid = s.sessionid and i.dateannulation is null
                     and not i.listeattente) \gset
select min(sessionid) as no_room_session from stage.session where salleformationid is null \gset
select min(contactid) as contact from contact.contact \gset

call outils.mv2_inscrire(:contact, :open_session, null, null);
call outils.mv2_inscrire(:contact, :full_session, null, null);
call outils.mv2_inscrire(:contact, :no_room_session, null, null);
\set ON_ERROR_STOP off
\set VERBOSITY verbose
call outils.mv2_inscrire(:contact, :open_session, null, null);
call outils.mv2_inscrire(:contact, -1, null, null);
call outils.mv2_inscrire(-1, :open_session, null, null);
call outils.mv2_inscrire(:contact, :open_session, null, null, 150::smallint);
\set VERBOSITY default
\set ON_ERROR_STOP on

-- What the calls left in the copy.
select inscriptionid, sessionid, contactid, remise, listeattente
from outils.mv2_inscription
where contactid = :contact and datecreation >= current_date
order by inscriptionid;

drop procedure outils.mv2_inscrire(integer, integer, smallint);
drop table outils.mv2_inscription;
