-- Clip D5.4: pg_stat_statements read by the DBA. Lab database, psql; needs 00-setup.sql
-- (the extension). Resets the entries of this database only, plays a small workload, then
-- lists the statements that cost the most, as a DBA reads them every morning.
select pg_stat_statements_reset(0, (select oid from pg_database where datname = current_database()), 0)
       is not null as reset_done \g /dev/null

select count(*) from inscription.facture where relance = 0 \g /dev/null
select count(*) from inscription.facture where relance = 3 \g /dev/null
select count(*) from inscription.facture where relance = 5 \g /dev/null
select s.sessionid, count(*) from stage.session s
join inscription.inscription i on i.sessionid = s.sessionid
where s.datedebut >= date '2019-01-01' group by s.sessionid \g /dev/null
select c.nom, count(*) from contact.contact c
join inscription.inscription i on i.contactid = c.contactid
group by c.nom order by count(*) desc limit 10 \g /dev/null
select count(*) from contact.prospectus where cp like '75%' \g /dev/null

-- The statements of this database, the most expensive first.
select queryid, calls, round(total_exec_time::numeric, 1) as total_ms,
       round(mean_exec_time::numeric, 2) as mean_ms, rows,
       shared_blks_hit as hit, shared_blks_read as read, temp_blks_written as temp_written,
       left(regexp_replace(query, '\s+', ' ', 'g'), 50) as query
from pg_stat_statements
where dbid = (select oid from pg_database where datname = current_database())
  and query not like '%pg_stat_statements%'
order by total_exec_time desc
limit 5;

-- The extension counts for the whole instance, whatever the database it was created in.
select max_entries, dealloc
from pg_stat_statements_info,
     lateral (select setting::int as max_entries from pg_settings
              where name = 'pg_stat_statements.max') m;
