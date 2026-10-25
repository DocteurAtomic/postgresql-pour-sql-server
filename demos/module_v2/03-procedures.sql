-- Clip V2.3: procedures and transactions. Lab database, psql.
-- Some statements fail on purpose: ON_ERROR_STOP is off around them.
-- Works on outils.mv2_inscription, a copy of inscription.inscription, dropped at the end.
create table outils.mv2_inscription as
select inscriptionid, sessionid, contactid
from inscription.inscription;

-- A SELECT without INTO in a procedure: no result set is sent to the client.
create procedure outils.mv2_count_inscriptions()
language plpgsql
as $$
begin
    select count(*) from outils.mv2_inscription;
end
$$;
\set ON_ERROR_STOP off
call outils.mv2_count_inscriptions();
\set ON_ERROR_STOP on

-- A batched purge: deletes the inscriptions of a session that does not exist,
-- commits after each batch, and returns the total in an INOUT parameter.
create procedure outils.mv2_purge_orphans(p_batch integer, inout p_deleted bigint default 0)
language plpgsql
as $$
declare
    deleted bigint;
begin
    loop
        delete from outils.mv2_inscription
        where inscriptionid in (
            select i.inscriptionid
            from outils.mv2_inscription as i
            where not exists (select 1 from stage.session as s where s.sessionid = i.sessionid)
            limit p_batch);
        get diagnostics deleted = row_count;
        exit when deleted = 0;
        p_deleted := p_deleted + deleted;
        commit;
        raise notice 'batch of %, % so far', deleted, p_deleted;
    end loop;
end
$$;

-- Called inside a transaction block, the procedure cannot commit.
begin;
\set ON_ERROR_STOP off
call outils.mv2_purge_orphans(3000);
\set ON_ERROR_STOP on
rollback;

-- Called on its own, it commits batch by batch.
call outils.mv2_purge_orphans(3000);
select count(*) as remaining from outils.mv2_inscription;

-- Two result sets: two cursors, returned as INOUT refcursor parameters.
create procedure outils.mv2_session_report(
    p_sessionid integer,
    inout c_session refcursor default 'c_session',
    inout c_inscriptions refcursor default 'c_inscriptions')
language plpgsql
as $$
begin
    open c_session for
        select sessionid, stageid, datedebut, duree
        from stage.session
        where sessionid = p_sessionid;
    open c_inscriptions for
        select inscriptionid, contactid, present
        from inscription.inscription
        where sessionid = p_sessionid
        order by inscriptionid
        limit 5;
end
$$;

-- The cursors live until the end of the transaction: read them inside it.
begin;
call outils.mv2_session_report(45);
fetch all from c_session;
fetch all from c_inscriptions;
commit;

-- In autocommit, the transaction ends with the CALL, and the cursors with it.
call outils.mv2_session_report(45);
\set ON_ERROR_STOP off
fetch all from c_session;
\set ON_ERROR_STOP on

drop procedure outils.mv2_session_report(integer, refcursor, refcursor);
drop procedure outils.mv2_purge_orphans(integer, bigint);
drop procedure outils.mv2_count_inscriptions();
drop table outils.mv2_inscription;
