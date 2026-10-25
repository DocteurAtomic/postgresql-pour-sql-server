-- Clip V2.2: functions. Lab database, psql.
-- One statement fails on purpose: ON_ERROR_STOP is off around it.

-- Contact.GetNbInscriptions of the SQL Server database, ported twice.
-- In SQL, with the standard body (RETURN), checked when the function is created.
create function outils.mv2_nb_inscriptions_sql(p_contactid integer)
returns bigint
language sql
stable
return (select count(*) from inscription.inscription where contactid = p_contactid);

-- In PL/pgSQL: the body is a string, between dollar quotes.
create function outils.mv2_nb_inscriptions(p_contactid integer)
returns bigint
language plpgsql
stable
as $$
begin
    return (select count(*) from inscription.inscription where contactid = p_contactid);
end
$$;

select outils.mv2_nb_inscriptions_sql(16707) as in_sql,
       outils.mv2_nb_inscriptions(16707) as in_plpgsql;
\df outils.mv2_nb*

-- A missing table: the SQL standard body is refused at creation, the PL/pgSQL string is
-- accepted and fails at the first call.
\set ON_ERROR_STOP off
create function outils.mv2_missing_sql()
returns bigint
language sql
return (select count(*) from outils.no_such_table);
create function outils.mv2_missing_plpgsql()
returns bigint
language plpgsql
as $$
begin
    return (select count(*) from outils.no_such_table);
end
$$;
select outils.mv2_missing_plpgsql();
\set ON_ERROR_STOP on
drop function outils.mv2_missing_plpgsql();

-- A scalar function made of an expression is inlined: the plan shows the expression.
create function outils.mv2_net_price(p_price numeric, p_discount smallint)
returns numeric
language sql
immutable
return p_price * (1 - p_discount / 100.0);
explain (verbose, costs off)
select outils.mv2_net_price(price, discount) as net_price
from (values (2500.00, 10::smallint), (1800.00, 0::smallint)) as v (price, discount);

-- With a subquery, the function stays a call, executed for each row.
explain (verbose, costs off)
select contactid, outils.mv2_nb_inscriptions_sql(contactid) as inscriptions
from contact.contact
where nom = 'Dupont';

-- Contact.GetNbInscriptionsTableInline, ported as a table function in SQL...
create function outils.mv2_inscriptions_tab_sql(p_contactid integer)
returns table (contactid integer, nb_inscriptions bigint)
language sql
stable
begin atomic
    select i.contactid, count(*)
    from inscription.inscription as i
    where i.contactid = p_contactid
    group by i.contactid;
end;

-- ... and in PL/pgSQL, the equivalent of a multi-statement function.
create function outils.mv2_inscriptions_tab(p_contactid integer)
returns table (contactid integer, nb_inscriptions bigint)
language plpgsql
stable
as $$
begin
    return query
    select i.contactid, count(*)
    from inscription.inscription as i
    where i.contactid = p_contactid
    group by i.contactid;
end
$$;

-- The SQL function is inlined into the query, the PL/pgSQL one is a Function Scan.
explain (analyze, costs on, buffers off)
select c.nom, c.prenom, t.nb_inscriptions
from contact.contact as c
cross join lateral outils.mv2_inscriptions_tab_sql(c.contactid) as t
where c.nom = 'Dupont';
explain (analyze, costs on, buffers off)
select c.nom, c.prenom, t.nb_inscriptions
from contact.contact as c
cross join lateral outils.mv2_inscriptions_tab(c.contactid) as t
where c.nom = 'Dupont';

-- Volatility: a VOLATILE function cannot be an index condition, a STABLE one can.
create function outils.mv2_cutoff_volatile()
returns date
language plpgsql
volatile
as $$
begin
    return date '2020-12-01';
end
$$;
create function outils.mv2_cutoff_stable()
returns date
language plpgsql
stable
as $$
begin
    return date '2020-12-01';
end
$$;
explain (analyze, costs off, buffers off)
select sessionid from stage.session where datedebut >= outils.mv2_cutoff_volatile();
explain (analyze, costs off, buffers off)
select sessionid from stage.session where datedebut >= outils.mv2_cutoff_stable();

-- An index expression demands an IMMUTABLE function.
create function outils.mv2_year_stable(p_date date)
returns integer
language plpgsql
stable
as $$
begin
    return extract(year from p_date);
end
$$;
\set ON_ERROR_STOP off
create index mv2_session_year on stage.session (outils.mv2_year_stable(datedebut));
\set ON_ERROR_STOP on

drop function outils.mv2_year_stable(date);
drop function outils.mv2_cutoff_stable();
drop function outils.mv2_cutoff_volatile();
drop function outils.mv2_inscriptions_tab(integer);
drop function outils.mv2_inscriptions_tab_sql(integer);
drop function outils.mv2_net_price(numeric, smallint);
drop function outils.mv2_nb_inscriptions(integer);
drop function outils.mv2_nb_inscriptions_sql(integer);
