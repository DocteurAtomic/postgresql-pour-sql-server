-- Module V5, setup. Lab database (pachadataformation), psql:
--   docker compose exec db psql -U postgres -d pachadataformation -f /demos/module_v5/00-setup.sql
-- The port has no jsonb, array or range column, and inscription.evaluation is empty.
-- This script creates what the module needs, in the outils schema, with the mv5_ prefix:
-- outils.mv5_evaluation, one jsonb evaluation per attended inscription, as a web form would
-- send it. The values are computed from the identifiers, so every run gives the same rows.
-- btree_gist is needed by the exclusion constraint of clip V5.5. 99-cleanup.sql drops all.

create extension if not exists btree_gist;

select count(*) as evaluations_in_the_port from inscription.evaluation;

create table outils.mv5_evaluation (
    evaluationid integer generated always as identity primary key,
    doc jsonb not null
);

insert into outils.mv5_evaluation (doc)
select jsonb_strip_nulls(jsonb_build_object(
           'inscriptionid', i.inscriptionid,
           'sessionid', i.sessionid,
           'date', s.datedebut + coalesce(s.duree, 1),
           'notes', jsonb_build_object(
               'animation', 1 + (i.inscriptionid * 7) % 5,
               'support', 1 + (i.inscriptionid * 3) % 5,
               'exercices', 1 + (i.inscriptionid * 11) % 5),
           'recommande', i.inscriptionid % 4 <> 0,
           'themes', case i.inscriptionid % 6
                         when 0 then '["rythme", "exercices"]'::jsonb
                         when 1 then '["support"]'::jsonb
                         when 2 then '["salle", "rythme"]'::jsonb
                         when 3 then '[]'::jsonb
                         when 4 then '["exercices"]'::jsonb
                         else '["formateur", "support", "exercices"]'::jsonb
                     end,
           'commentaire', case when i.inscriptionid % 9 = 0
                               then 'Trop de théorie le premier jour.' end))
from inscription.inscription as i
join stage.session as s on s.sessionid = i.sessionid
where i.present
order by i.inscriptionid;

analyze outils.mv5_evaluation;

select count(*) as evaluations,
       pg_size_pretty(pg_table_size('outils.mv5_evaluation')) as table_size
from outils.mv5_evaluation;
select doc from outils.mv5_evaluation order by evaluationid limit 1;
