-- Module V5 exercise, starting point. Lab database, psql.
-- Creates the empty table of the documents and shows, flat, what one document must hold.
-- 2-solution.sql drops the table at its end; to start again without it:
--   drop table if exists outils.mv5_stage_doc;

create table outils.mv5_stage_doc (
    stageid integer primary key,
    doc jsonb not null
);

-- The target, for stage 12 (abridged):
-- {"stageid": 12, "titre": "...", "duree": 5,
--  "sessions": [{"sessionid": 259, "debut": "2011-02-01", "salle": 29,
--                "inscrits": [contactid, contactid, ...]}, ...]}

-- The rows it comes from.
select st.stageid, sl.titre, st.duree, s.sessionid, s.datedebut, s.salleformationid,
       i.contactid
from stage.stage as st
join stage.stagelangue as sl on sl.stageid = st.stageid and sl.languecd = 'FR'
left join stage.session as s on s.stageid = st.stageid
left join inscription.inscription as i on i.sessionid = s.sessionid
where st.stageid = 12
order by s.datedebut, i.contactid
limit 10;
