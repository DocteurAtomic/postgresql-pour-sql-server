-- Module V4, setup. Lab database (pachadataformation), psql:
--   docker compose exec db psql -U postgres -d pachadataformation -f /demos/module_v4/00-setup.sql
-- The base is too small for a query to be slow, so this script generates
-- outils.mv4_inscription: the 30,436 inscriptions copied 99 times, 3,013,164 rows, about
-- 550 MB, in about fifteen seconds. Each row gets a creation time 100 seconds after the
-- previous one (January 2017 to July 2026), in the physical order of the table, like a log
-- that only grows; a jsonb column, a text array and a date range for GIN and GiST.
-- The values are computed from the row number, not drawn at random: every run gives the
-- same table. The table has only its primary key; each clip creates its indexes and drops
-- them at the end. 99-cleanup.sql drops the table and the extension.
create extension if not exists pg_trgm;   -- clip V4.3

drop table if exists outils.mv4_inscription;
create table outils.mv4_inscription as
with source as materialized (
    select row_number() over (order by i.inscriptionid) - 1 as rn,
           i.sessionid, i.contactid, i.remise, i.present, i.listeattente,
           i.dateannulation is not null as cancelled,
           c.email, coalesce(s.duree, 3) as duree
    from inscription.inscription as i
    left join contact.contact as c on c.contactid = i.contactid
    left join stage.session as s on s.sessionid = i.sessionid
), numbered as (
    select g * 30436 + source.rn + 1 as n, source.*,
           timestamp '2017-01-01 08:00' + (g * 30436 + source.rn + 1) * interval '100 seconds' as created
    from generate_series(0, 98) as g
    cross join source
)
select n as inscriptionid, sessionid, contactid, email,
       created as datecreation,
       remise, present, listeattente,
       case when cancelled then created::date + 10 end as dateannulation,
       -- 60 % entreprise, 30 % opco, 9 % cpf, 1 % personnel; one row in 997 has a key more.
       jsonb_build_object(
           'financement', case when n % 100 < 60 then 'entreprise'
                               when n % 100 < 90 then 'opco'
                               when n % 100 < 99 then 'cpf'
                               else 'personnel' end,
           'repas', n % 3 = 0)
       || case when n % 997 = 0 then '{"amenagement": "pmr"}'::jsonb else '{}'::jsonb end as options,
       -- 70 % presentiel, 30 % distanciel, plus certification (5 %) and urgent (0.2 %).
       case when n % 10 < 7 then array['presentiel'] else array['distanciel'] end
       || case when n % 20 = 0 then array['certification'] else array[]::text[] end
       || case when n % 499 = 0 then array['urgent'] else array[]::text[] end as tags,
       -- The session days: one to three months after the inscription, for duree days.
       daterange(created::date + 30 + (n % 60)::int,
                 created::date + 30 + (n % 60)::int + duree) as periode
from numbered
order by n;

alter table outils.mv4_inscription add primary key (inscriptionid);
-- VACUUM sets the visibility map (Index Only Scan, clip V4.1) and the hint bits.
vacuum (analyze) outils.mv4_inscription;

select relpages, reltuples::bigint as rows,
       pg_size_pretty(pg_table_size('outils.mv4_inscription')) as table_size,
       relallvisible
from pg_class
where oid = 'outils.mv4_inscription'::regclass;

select min(datecreation), max(datecreation),
       count(*) filter (where dateannulation is not null) as cancelled,
       count(*) filter (where listeattente) as waiting_list
from outils.mv4_inscription;
