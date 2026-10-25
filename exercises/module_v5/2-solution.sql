-- Module V5 exercise, solution. Lab database, psql.
-- Builds one jsonb document per stage (its sessions, their contacts), queries it, checks it
-- against the tables, and drops everything it created.

-- 1. The documents. Four traps: a stage without session would get "sessions": [null],
-- a session without inscription "inscrits": [null] (FILTER and coalesce avoid both), the
-- port holds 5,000 inscriptions entered twice (DISTINCT), and 166 without a contact, whose
-- NULL would land in the array as a JSON null (FILTER again).
drop table if exists outils.mv5_stage_doc;  -- left by 1-start.sql
create table outils.mv5_stage_doc (
    stageid integer primary key,
    doc jsonb not null
);

insert into outils.mv5_stage_doc (stageid, doc)
select st.stageid,
       jsonb_build_object(
           'stageid', st.stageid,
           'titre', sl.titre,
           'duree', st.duree,
           'sessions', coalesce(
               jsonb_agg(jsonb_build_object(
                             'sessionid', se.sessionid,
                             'debut', se.datedebut,
                             'salle', se.salleformationid,
                             'inscrits', se.inscrits)
                         order by se.datedebut, se.sessionid)
                   filter (where se.sessionid is not null),
               '[]'::jsonb))
from stage.stage as st
join stage.stagelangue as sl on sl.stageid = st.stageid and sl.languecd = 'FR'
left join lateral (
    select s.sessionid, s.datedebut, s.salleformationid,
           coalesce((select jsonb_agg(distinct i.contactid)
                                filter (where i.contactid is not null)
                     from inscription.inscription as i
                     where i.sessionid = s.sessionid), '[]'::jsonb) as inscrits
    from stage.session as s
    where s.stageid = st.stageid
) as se on true
group by st.stageid, sl.titre, st.duree;

select count(*) as documents,
       count(*) filter (where doc -> 'sessions' = '[]') as without_session,
       pg_size_pretty(pg_table_size('outils.mv5_stage_doc')) as table_size
from outils.mv5_stage_doc;
select stageid, pg_column_size(doc) as stored_bytes, octet_length(doc::text) as text_bytes
from outils.mv5_stage_doc
order by stored_bytes desc
limit 3;

-- 2. Check against the tables: sessions, then distinct (session, contact) pairs. The
-- inscriptions of the 8,922 orphans point to no session: they are in no document.
select (select sum(jsonb_array_length(doc -> 'sessions')) from outils.mv5_stage_doc) as sessions_in_docs,
       (select count(*) from stage.session) as sessions_in_table;
select (select count(*)
        from outils.mv5_stage_doc as d,
             json_table(d.doc, '$.sessions[*]'
                 columns (sessionid integer path '$.sessionid',
                          nested path '$.inscrits[*]' columns (contactid integer path '$'))) as jt
        -- NESTED PATH is an outer join: a session with no contact gives one row, NULL.
        where jt.contactid is not null) as pairs_in_docs,
       (select count(*)
        from (select distinct i.sessionid, i.contactid
              from inscription.inscription as i
              join stage.session as s on s.sessionid = i.sessionid
              where i.contactid is not null) as p) as pairs_in_tables,
       (select count(*)
        from inscription.inscription as i
        where not exists (select 1 from stage.session as s where s.sessionid = i.sessionid)) as orphan_inscriptions;

-- 3. The stages of contact 8049: containment through two arrays, with a GIN index.
create index mv5_stage_doc_gin on outils.mv5_stage_doc using gin (doc jsonb_path_ops);
select stageid, doc ->> 'titre' as titre
from outils.mv5_stage_doc
where doc @> '{"sessions": [{"inscrits": [8049]}]}'
order by stageid;
-- 168 documents: the planner prefers reading the table. Without a sequential scan:
set enable_seqscan = off;
explain (analyze, costs off)
select stageid from outils.mv5_stage_doc where doc @> '{"sessions": [{"inscrits": [8049]}]}';
reset enable_seqscan;

-- The same question asked to the tables.
select distinct s.stageid
from inscription.inscription as i
join stage.session as s on s.sessionid = i.sessionid
where i.contactid = 8049
order by s.stageid;

-- 4. The sessions of a stage as rows, with the number of contacts.
select jt.sessionid, jt.debut, jt.salle, jsonb_array_length(jt.inscrits) as contacts
from outils.mv5_stage_doc as d,
     json_table(d.doc, '$.sessions[*]'
         columns (sessionid integer path '$.sessionid',
                  debut date path '$.debut',
                  salle integer path '$.salle',
                  inscrits jsonb path '$.inscrits')) as jt
where d.stageid = 12
order by jt.debut
limit 5;

-- 5. Adding one contact to one session rewrites the whole document of the stage.
select pg_column_size(doc) as bytes_before from outils.mv5_stage_doc where stageid = 12;
update outils.mv5_stage_doc as d
set doc = jsonb_set(d.doc, array['sessions', (x.pos - 1)::text, 'inscrits'],
                    (d.doc #> array['sessions', (x.pos - 1)::text, 'inscrits']) || '1')
from (select e.pos
      from outils.mv5_stage_doc as d2,
           jsonb_array_elements(d2.doc -> 'sessions') with ordinality as e (s, pos)
      where d2.stageid = 12 and (e.s ->> 'sessionid')::integer = 208) as x
where d.stageid = 12;
select jsonb_path_query(doc, '$.sessions[*] ? (@.sessionid == 208).inscrits') as session_208
from outils.mv5_stage_doc where stageid = 12;

drop table outils.mv5_stage_doc;
