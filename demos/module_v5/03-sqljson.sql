-- Clip V5.3: the SQL/JSON functions. Lab database, psql, after 00-setup.sql.
-- One statement fails on purpose: ON_ERROR_STOP is off around it.

-- JSON_VALUE for a scalar, JSON_QUERY for an object or an array, as in T-SQL.
select json_value(doc, '$.notes.animation' returning integer) as animation,
       json_value(doc, '$.date' returning date) as eval_date,
       json_query(doc, '$.themes') as themes,
       json_value(doc, '$.notes') as notes_as_value
from outils.mv5_evaluation
where evaluationid = 1;

-- Errors: NULL by default, as with the lax mode of T-SQL; ERROR ON ERROR to see them.
\set ON_ERROR_STOP off
select json_value(doc, '$.notes' error on error) from outils.mv5_evaluation where evaluationid = 1;
\set ON_ERROR_STOP on
select json_value(doc, 'strict $.commentaire') as strict_missing,
       json_value(doc, '$.commentaire' default 'aucun' on empty) as with_default
from outils.mv5_evaluation
where evaluationid = 1;

-- JSON_EXISTS, called JSON_PATH_EXISTS in SQL Server.
select count(*) filter (where json_exists(doc, '$.commentaire')) as with_comment,
       count(*) filter (where json_exists(doc, '$.notes ? (@.animation == 1)')) as animation_1
from outils.mv5_evaluation;

-- JSON_TABLE (17): the document as rows and columns, a NESTED PATH for the array.
select jt.*
from outils.mv5_evaluation as e,
     json_table(e.doc, '$'
         columns (inscriptionid integer path '$.inscriptionid',
                  animation integer path '$.notes.animation',
                  recommande boolean path '$.recommande',
                  nested path '$.themes[*]' columns (theme text path '$'))) as jt
where e.evaluationid <= 3
order by jt.inscriptionid, jt.theme;

-- The same result with the PostgreSQL functions that predate SQL/JSON.
select (e.doc ->> 'inscriptionid')::integer as inscriptionid, t.theme
from outils.mv5_evaluation as e
left join lateral jsonb_array_elements_text(e.doc -> 'themes') as t (theme) on true
where e.evaluationid <= 3
order by 1, 2;

-- Building JSON: JSON_OBJECT and JSON_ARRAYAGG (16) on both engines.
select json_object('sessionid': s.sessionid,
                   'debut': s.datedebut,
                   'salle': s.salleformationid,
                   'inscrits': json_arrayagg(i.contactid order by i.contactid)) as session_doc
from stage.session as s
join inscription.inscription as i on i.sessionid = s.sessionid
where s.sessionid = 40
group by s.sessionid, s.datedebut, s.salleformationid;

-- NULL: JSON_ARRAY drops it, JSON_OBJECT keeps it, json_build_array keeps it.
select json_array(1, 2, null) as json_array,
       json_object('salle': null) as json_object,
       json_build_array(1, 2, null) as build_array,
       json_object('salle': null absent on null) as absent;

-- FOR JSON PATH: json_agg over rows, or jsonb_agg of jsonb_build_object.
select jsonb_agg(jsonb_build_object('sessionid', s.sessionid, 'debut', s.datedebut)
                 order by s.sessionid) as sessions_of_stage_12
from stage.session as s
where s.stageid = 12 and s.salleformationid is not null;
