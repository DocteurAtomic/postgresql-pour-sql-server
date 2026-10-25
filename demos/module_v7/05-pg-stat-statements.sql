-- Clip V7.5: pg_stat_statements, from the developer's side. Lab database, psql, one session.
-- 00-setup.sql created the extension; the lab loads its library at startup. The script
-- resets the statistics of this database only, then plays a small workload.
select pg_stat_statements_reset(0, (select oid from pg_database where datname = current_database()), 0)
       is not null as reset;

\o /dev/null
-- The application: the same query with three values, then the function of 00-setup.sql.
select count(*), sum(montantttc) from inscription.facture where relance = 29;
select count(*), sum(montantttc) from inscription.facture where relance = 0;
select count(*), sum(montantttc) from inscription.facture where relance = 41;
select outils.mv7_enrolled(0::smallint);
select outils.mv7_enrolled(29::smallint);
\o

-- One line per normalized query: the constants became $1. Times vary from run to run.
select calls, rows, round(total_exec_time::numeric, 1) as total_ms,
       shared_blks_hit + shared_blks_read as blocks, toplevel,
       left(regexp_replace(query, '\s+', ' ', 'g'), 80) as query
from pg_stat_statements
where dbid = (select oid from pg_database where datname = current_database())
  and query not like '%pg_stat_statements%'
order by total_exec_time desc;

-- The query inside the function only appears with track = all (superuser, this session).
set pg_stat_statements.track = 'all';
\o /dev/null
select outils.mv7_enrolled(0::smallint);
\o
select calls, rows, toplevel, left(regexp_replace(query, '\s+', ' ', 'g'), 80) as query
from pg_stat_statements
where dbid = (select oid from pg_database where datname = current_database())
  and query like '%inscriptionfacture%';
reset pg_stat_statements.track;
