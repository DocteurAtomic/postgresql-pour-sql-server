-- Clip V2.1: the DO block and the variables. Lab database, psql.
-- Some statements fail on purpose: ON_ERROR_STOP is off around them.

-- No variable in plain SQL: DECLARE declares a cursor, and @ is not part of a name.
\set ON_ERROR_STOP off
declare @n integer = 3;
declare n integer;
\set ON_ERROR_STOP on

-- A DO block runs an anonymous PL/pgSQL block. It takes no parameter and returns nothing.
\set ON_ERROR_STOP off
do $$
begin
    select count(*) from stage.session;
end
$$;
\set ON_ERROR_STOP on

-- SELECT ... INTO assigns the variables; RAISE NOTICE prints, as PRINT does.
do $$
declare
    sessions bigint;
    first_date stage.session.datedebut%type;
begin
    select count(*), min(datedebut) into sessions, first_date from stage.session;
    raise notice 'sessions: %, first one on %', sessions, first_date;
end
$$;

-- Several rows: INTO keeps the first one. No row: the variable becomes NULL.
do $$
declare
    d date := date '1900-01-01';
begin
    select datedebut into d from stage.session where stageid = 12 order by sessionid;
    raise notice 'first row: %', d;
    select datedebut into d from stage.session where stageid = -1;
    raise notice 'no row: %', d;
end
$$;

-- STRICT demands exactly one row, and raises an error otherwise.
\set ON_ERROR_STOP off
do $$
declare
    d date;
begin
    select datedebut into strict d from stage.session where stageid = 12;
end
$$;
do $$
declare
    d date;
begin
    select datedebut into strict d from stage.session where stageid = -1;
end
$$;
\set ON_ERROR_STOP on

-- psql variables: text substituted by the client before the query is sent.
\set stage_id 12
select count(*) as sessions from stage.session where stageid = :stage_id;
select max(datedebut) as last_date from stage.session \gset
\echo :last_date
select sessionid, stageid from stage.session where datedebut = :'last_date';
