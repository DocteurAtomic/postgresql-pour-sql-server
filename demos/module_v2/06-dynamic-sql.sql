-- Clip V2.6: dynamic SQL. Lab database, psql.
-- Some statements fail on purpose: ON_ERROR_STOP is off around them.

-- In plain SQL, EXECUTE runs a prepared statement, not a string.
\set ON_ERROR_STOP off
execute 'select count(*) from contact.prospectus';
\set ON_ERROR_STOP on

-- format() builds the text: %I quotes a name, %L a literal, %s inserts as is.
select format('select count(*) from %I.%I where nom = %L', 'contact', 'prospectus', 'O''Neal') as query;
select format('%I, %I, %L, %L', 'nom', 'Nom', 'O''Neal', null::text) as quoted;

-- A function that concatenates its parameter into the text: open to injection.
create function outils.mv2_count_unsafe(p_nom text)
returns bigint
language plpgsql
as $$
declare
    n bigint;
begin
    execute 'select count(*) from contact.prospectus where nom = ''' || p_nom || ''''
        into n;
    return n;
end
$$;
select outils.mv2_count_unsafe('Stone') as stone;
\set ON_ERROR_STOP off
select outils.mv2_count_unsafe('O''Neal') as oneal;
\set ON_ERROR_STOP on
select outils.mv2_count_unsafe('x'' or ''x'' = ''x') as injected;

-- The same with a parameter: EXECUTE ... USING, the equivalent of sp_executesql.
create function outils.mv2_count_safe(p_nom text)
returns bigint
language plpgsql
as $$
declare
    n bigint;
begin
    execute 'select count(*) from contact.prospectus where nom = $1'
        into n
        using p_nom;
    return n;
end
$$;
select outils.mv2_count_safe('O''Neal') as oneal,
       outils.mv2_count_safe('x'' or ''x'' = ''x') as injected;

-- Contact.RechercheProspect, ported without the OR ... IS NULL: the WHERE clause gets
-- only the criteria given, and the values stay parameters.
create function outils.mv2_search_prospects(p_nom text default null, p_ville text default null)
returns table (nom varchar, prenom varchar, cp varchar, ville varchar)
language plpgsql
stable
as $$
declare
    sql_text text := 'select p.nom, p.prenom, p.cp, p.ville from contact.prospectus as p where true';
begin
    if p_nom is not null then
        sql_text := sql_text || ' and p.nom = $1';
    end if;
    if p_ville is not null then
        sql_text := sql_text || ' and p.ville = $2';
    end if;
    sql_text := sql_text || ' order by p.nom, p.prenom limit 5';
    raise notice '%', sql_text;
    return query execute sql_text using p_nom, p_ville;
end
$$;
select * from outils.mv2_search_prospects(p_nom => 'Stone', p_ville => 'Arlington');
select * from outils.mv2_search_prospects(p_ville => 'Columbus');

-- A name from the catalog: %I in the text, never a parameter.
do $$
declare
    t record;
    n bigint;
begin
    for t in
        select table_schema, table_name
        from information_schema.tables
        where table_schema = 'stage' and table_type = 'BASE TABLE'
        order by table_name
    loop
        execute format('select count(*) from %I.%I', t.table_schema, t.table_name) into n;
        raise notice '%.%: % rows', t.table_schema, t.table_name, n;
    end loop;
end
$$;

drop function outils.mv2_search_prospects(text, text);
drop function outils.mv2_count_safe(text);
drop function outils.mv2_count_unsafe(text);
