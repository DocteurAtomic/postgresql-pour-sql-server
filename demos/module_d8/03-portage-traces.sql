-- Clip D8.3: traces of an earlier migration, read in the lab database. Lab database
-- (pachadataformation), psql, read only:
--   docker compose exec db psql -U postgres -d pachadataformation -f /demos/module_d8/03-portage-traces.sql

-- 1. Names and types copied without a second look.
select indexname
from pg_indexes
where schemaname = 'inscription' and tablename = 'inscription' and indexname like '<%';

select table_schema, table_name, column_name, data_type, character_maximum_length
from information_schema.columns
where (table_schema, table_name, column_name) in (('stage', 'session', 'statut'),
                                                  ('stage', 'session', 'intraentrerprise'),
                                                  ('reference', 'ville', 'codeinsee'))
order by column_name;

-- 2. A default that was a function call in SQL Server and is now a string.
select column_default
from information_schema.columns
where table_schema = 'formateur' and table_name = 'formateur' and column_name = 'creationuser';

-- 3. Two indexes that another one already covers: same leading column.
select indexname, indexdef
from pg_indexes
where schemaname = 'inscription' and tablename = 'facture' and indexname like 'nix_%'
order by indexname;

-- 4. A table named after a SQL Server index type, now an ordinary heap with no index.
select c.relname, c.relkind, am.amname as access_method,
       (select count(*) from pg_index i where i.indrelid = c.oid) as indexes
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
left join pg_am am on am.oid = c.relam
where n.nspname = 'inscription' and c.relname in ('facture', 'facturecolumnstore');

-- 5. Data that a constraint would have refused: no foreign key from inscription to session.
select count(*) as inscriptions,
       count(*) filter (where s.sessionid is null) as without_session,
       count(*) filter (where i.contactid is null) as without_contact
from inscription.inscription i
left join stage.session s on s.sessionid = i.sessionid;

select conname
from pg_constraint
where conrelid = 'inscription.inscription'::regclass and contype = 'f';

-- 6. The same registration twice: (sessionid, contactid) pairs entered two times.
select count(*) as pairs,
       count(*) filter (where max_id - min_id = 10000) as ids_10000_apart,
       count(*) filter (where contactid is null) as without_contact
from (select sessionid, contactid, min(inscriptionid) as min_id, max(inscriptionid) as max_id
      from inscription.inscription
      group by sessionid, contactid
      having count(*) > 1) d;

-- 7. Values that the source type could not hold: INSEE codes stored as numbers.
select count(*) as communes,
       count(*) filter (where codeinsee < 10000) as leading_zero_lost
from reference.ville;

select count(*) filter (where coderemise ~ '^ +$') as blank_codes,
       count(*) filter (where coderemise is null) as null_codes
from inscription.facture;
