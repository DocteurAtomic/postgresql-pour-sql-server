-- Module V6, setup. Lab database (pachadataformation), psql:
--   docker compose exec db psql -U postgres -d pachadataformation -f /demos/module_v6/00-setup.sql
-- Creates the four extensions of the module (pg_trgm, unaccent, fuzzystrmatch, vector) and
-- four tables in the outils schema, with the mv6_ prefix. 99-cleanup.sql drops them all.
-- The description columns of stage.stagelangue are empty in the port, so the full text
-- search of clip V6.2 runs on outils.mv6_programme: one fictitious training program per
-- course, in French, put together from the product, the version and the level of its title.
-- The vectors of clip V6.4 come from no model: they are computed from the identifiers, so
-- every run gives the same rows.

create extension if not exists pg_trgm;        -- clip V6.3
create extension if not exists unaccent;       -- clip V6.3
create extension if not exists fuzzystrmatch;  -- clips V6.1 and V6.3
create extension if not exists vector;         -- clip V6.4

-- 1. The training programs (clip V6.2): 168 courses, one text each.
drop table if exists outils.mv6_programme;
create table outils.mv6_programme as
with course as (
    select sl.stageid, sl.titre, s.duree,
           substring(sl.titre from '^(Firebird|MySQL|Oracle|PostgreSQL|SQL Server)') as produit,
           substring(sl.titre from '(Administration|Avancé|Découverte|Développement|Expertise|Mise à niveau|Optimisation|Prise en Main)$') as niveau
    from stage.stagelangue as sl
    join stage.stage as s on s.stageid = sl.stageid
    where sl.languecd = 'FR'
)
select stageid, titre, produit, niveau,
       case niveau
           when 'Administration' then
               'Ce stage forme les administrateurs à l''exploitation quotidienne de ' || produit
               || '. Au programme : installation et configuration du serveur, gestion des comptes et des droits, '
               || 'sauvegardes et restaurations, surveillance de l''activité et planification des tâches de maintenance.'
           when 'Avancé' then
               'Pour les utilisateurs qui pratiquent déjà ' || produit || ' et veulent aller plus loin : '
               || 'requêtes complexes, transactions et verrous, procédures stockées et déclencheurs, '
               || 'gestion des erreurs et sécurité des accès.'
           when 'Découverte' then
               'Une première approche de ' || produit || ' pour les décideurs et les chefs de projet : '
               || 'architecture du moteur, éditions et licences, outils d''administration, '
               || 'positionnement face aux autres bases de données.'
           when 'Développement' then
               'Les développeurs apprennent à écrire du SQL efficace avec ' || produit || ' : '
               || 'jointures, sous-requêtes, fonctions de fenêtrage, procédures stockées et déclencheurs, '
               || 'accès aux données depuis une application.'
           when 'Expertise' then
               'Le stage d''expertise décrit le fonctionnement interne du moteur ' || produit || ' : '
               || 'stockage des données sur le disque, journal des transactions, optimiseur de requêtes, '
               || 'diagnostic des incidents en production.'
           when 'Mise à niveau' then
               'Pour les équipes qui passent à une nouvelle version de ' || produit || ' : '
               || 'les nouveautés de la version, les incompatibilités à corriger, '
               || 'la migration des bases existantes et des applications.'
           when 'Optimisation' then
               'Optimiser les performances de ' || produit || ' : lecture des plans d''exécution, choix des index, '
               || 'statistiques de l''optimiseur, réécriture des requêtes lentes, réglage de la mémoire et des disques.'
           when 'Prise en Main' then
               'Les bases de ' || produit || ' en quelques jours : installation sur un poste, création d''une base, '
               || 'premières requêtes SQL, sauvegarde simple.'
       end
       || ' Durée : ' || duree || ' jours. '
       || case produit
              when 'SQL Server' then 'Les travaux pratiques se font dans SQL Server Management Studio.'
              when 'PostgreSQL' then 'Les travaux pratiques se font avec psql et pgAdmin.'
              when 'Oracle' then 'Les travaux pratiques se font avec SQL*Plus et SQL Developer.'
              when 'MySQL' then 'Les travaux pratiques se font avec le client mysql et MySQL Workbench.'
              when 'Firebird' then 'Les travaux pratiques se font avec isql et FlameRobin.'
          end as programme
from course;
alter table outils.mv6_programme add primary key (stageid);

-- 2. A copy of the contacts' names (clip V6.3), for the trigram and accent indexes.
drop table if exists outils.mv6_contact;
create table outils.mv6_contact as
select contactid, nom, prenom
from contact.contact;
alter table outils.mv6_contact add primary key (contactid);

-- 3. The courses as three-dimensional vectors (clip V6.4), built by hand: how much
--    administration, development and performance tuning each level contains, plus a small
--    offset taken from the identifier, so that two courses of the same level are not tied.
drop table if exists outils.mv6_stage_vecteur;
create table outils.mv6_stage_vecteur as
select stageid, titre,
       case niveau
           when 'Administration' then '[0.9, 0.1, 0.3]'
           when 'Avancé'         then '[0.3, 0.7, 0.5]'
           when 'Découverte'     then '[0.4, 0.3, 0.1]'
           when 'Développement'  then '[0.1, 0.9, 0.3]'
           when 'Expertise'      then '[0.6, 0.4, 0.7]'
           when 'Mise à niveau'  then '[0.6, 0.5, 0.2]'
           when 'Optimisation'   then '[0.3, 0.4, 0.9]'
           when 'Prise en Main'  then '[0.5, 0.4, 0.1]'
       end::vector(3)
       + ('[0, 0, ' || (stageid % 10) / 100.0 || ']')::vector(3) as embedding
from outils.mv6_programme;
alter table outils.mv6_stage_vecteur add primary key (stageid);

-- 4. 100,000 vectors of 16 dimensions for the index (clip V6.4). Each value is the
--    fractional part of a sine, a classic pseudo-random generator that needs no seed:
--    the same id always gives the same vector. categorie goes from 0 to 99, so a filter on
--    one category keeps 1 % of the rows.
drop table if exists outils.mv6_vecteur;
create table outils.mv6_vecteur as
select id, id % 100 as categorie,
       (select array_agg(abs(sin(id * 12.9898 + k * 78.233) * 43758.5453)
                         - floor(abs(sin(id * 12.9898 + k * 78.233) * 43758.5453))
                         order by k)
        from generate_series(1, 16) as k)::vector(16) as embedding
from generate_series(1, 100000) as id;
alter table outils.mv6_vecteur add primary key (id);

vacuum analyze outils.mv6_programme, outils.mv6_contact, outils.mv6_stage_vecteur, outils.mv6_vecteur;

select extname, extversion from pg_extension order by extname;
select relname, reltuples::bigint as rows, pg_size_pretty(pg_table_size(oid)) as size
from pg_class
where oid in ('outils.mv6_programme'::regclass, 'outils.mv6_contact'::regclass,
              'outils.mv6_stage_vecteur'::regclass,
              'outils.mv6_vecteur'::regclass)
order by relname;
select count(*) filter (where programme is null) as missing_programs,
       count(distinct niveau) as levels, count(distinct produit) as products
from outils.mv6_programme;
