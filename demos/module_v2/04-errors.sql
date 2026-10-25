-- Clip V2.4: errors. Lab database, psql.
-- Some statements fail on purpose: ON_ERROR_STOP is off around them.
-- The timings change from one run to the next; the transaction IDs do not.
create table outils.mv2_log (id integer primary key, label text);
insert into outils.mv2_log values (1, 'existing');

-- TRY ... CATCH becomes BEGIN ... EXCEPTION WHEN. The handler reads the error by
-- GET STACKED DIAGNOSTICS, and the work of the block is rolled back before it runs.
do $$
declare
    v_state text;
    v_message text;
    v_detail text;
    v_constraint text;
begin
    insert into outils.mv2_log values (2, 'inside the block');
    insert into outils.mv2_log values (1, 'duplicate');
exception
    when unique_violation then
        get stacked diagnostics
            v_state = returned_sqlstate,
            v_message = message_text,
            v_detail = pg_exception_detail,
            v_constraint = constraint_name;
        raise notice 'sqlstate %, constraint %', v_state, v_constraint;
        raise notice '%', v_message;
        raise notice '%', v_detail;
end
$$;
select id, label from outils.mv2_log order by id;

-- THROW becomes RAISE EXCEPTION, with an SQLSTATE and a hint. VERBOSITY verbose shows the code.
\set ON_ERROR_STOP off
\set VERBOSITY verbose
do $$
begin
    raise exception 'session % does not exist', 9999
        using errcode = 'no_data_found', hint = 'Check stage.session.';
end
$$;
do $$
begin
    raise exception 'no SQLSTATE given';
end
$$;
do $$
begin
    raise exception 'a code of our own' using errcode = 'MV201';
end
$$;
\set VERBOSITY default

-- RAISE without argument, in a handler, raises the error again, as THROW; does.
do $$
begin
    perform 1 / 0;
exception
    when others then
        raise notice 'caught %: %', sqlstate, sqlerrm;
        raise;
end
$$;
\set ON_ERROR_STOP on

-- The cost of the subtransaction: 200,000 iterations, without and with an EXCEPTION block.
do $$
declare
    t0 timestamptz;
    x integer := 0;
begin
    t0 := clock_timestamp();
    for i in 1..200000 loop
        x := x + 1;
    end loop;
    raise notice 'assignment, no block: % ms', round(extract(epoch from clock_timestamp() - t0) * 1000);
    t0 := clock_timestamp();
    for i in 1..200000 loop
        begin
            x := x + 1;
        exception
            when others then null;
        end;
    end loop;
    raise notice 'assignment, EXCEPTION block: % ms', round(extract(epoch from clock_timestamp() - t0) * 1000);
end
$$;

-- With a write, each block takes its own transaction ID.
create table outils.mv2_cost (id integer);
do $$
declare
    t0 timestamptz;
begin
    t0 := clock_timestamp();
    for i in 1..100000 loop
        insert into outils.mv2_cost values (i);
    end loop;
    raise notice 'insert, no block: % ms', round(extract(epoch from clock_timestamp() - t0) * 1000);
    t0 := clock_timestamp();
    for i in 1..100000 loop
        begin
            insert into outils.mv2_cost values (i);
        exception
            when others then null;
        end;
    end loop;
    raise notice 'insert, EXCEPTION block: % ms', round(extract(epoch from clock_timestamp() - t0) * 1000);
end
$$;

-- The next transaction ID, read without taking one, before and after 1,000 inserts.
select pg_snapshot_xmax(pg_current_snapshot()) as before \gset
do $$
begin
    for i in 1..1000 loop
        insert into outils.mv2_cost values (i);
    end loop;
end
$$;
select pg_snapshot_xmax(pg_current_snapshot())::text::bigint - :'before'::bigint as xids_without_block;
select pg_snapshot_xmax(pg_current_snapshot()) as before \gset
do $$
begin
    for i in 1..1000 loop
        begin
            insert into outils.mv2_cost values (i);
        exception
            when others then null;
        end;
    end loop;
end
$$;
select pg_snapshot_xmax(pg_current_snapshot())::text::bigint - :'before'::bigint as xids_with_block;

drop table outils.mv2_cost;
drop table outils.mv2_log;
