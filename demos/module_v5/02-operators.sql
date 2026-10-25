-- Clip V5.2: operators and paths. Lab database, psql, after 00-setup.sql.
-- Two statements fail on purpose: ON_ERROR_STOP is off around them.

-- One document of the module.
select jsonb_pretty(doc) from outils.mv5_evaluation where evaluationid = 1;

-- -> returns jsonb, ->> returns text; #> and #>> follow a path given as an array.
select doc -> 'notes' as notes_jsonb,
       doc -> 'notes' ->> 'animation' as animation_text,
       doc #>> '{notes,animation}' as by_path,
       doc -> 'themes' -> 0 as first_theme,
       doc ->> 'absent' as missing_key
from outils.mv5_evaluation
where evaluationid = 1;

-- ->> gives text: comparing it with a number is an error, a cast is needed.
\set ON_ERROR_STOP off
select count(*) from outils.mv5_evaluation where doc ->> 'sessionid' = 40;
select count(*) from outils.mv5_evaluation where doc -> 'sessionid' = 40;
\set ON_ERROR_STOP on
select count(*) as cast_text
from outils.mv5_evaluation where (doc ->> 'sessionid')::integer = 40;

-- Containment and key existence.
select count(*) filter (where doc @> '{"sessionid": 40}') as session_40,
       count(*) filter (where doc @> '{"notes": {"animation": 1}, "recommande": false}') as bad_and_not_recommended,
       count(*) filter (where doc @> '{"themes": ["salle"]}') as theme_salle,
       count(*) filter (where doc ? 'commentaire') as with_comment
from outils.mv5_evaluation;

-- jsonpath: a filter inside the document, and the values it finds.
select count(*) as mark_2_or_less
from outils.mv5_evaluation
where doc @? '$.notes.* ? (@ <= 2)';
select doc ->> 'inscriptionid' as inscriptionid,
       jsonb_path_query_array(doc, '$.notes.keyvalue() ? (@.value <= 2).key') as marks_2_or_less
from outils.mv5_evaluation
where doc @? '$.notes.* ? (@ <= 2)'
order by evaluationid
limit 3;

-- Without an index, @> reads the whole table.
explain (analyze, costs off)
select doc ->> 'inscriptionid' from outils.mv5_evaluation where doc @> '{"sessionid": 40}';

-- A GIN index on the column: @>, ?, @? and @@ can use it.
create index mv5_evaluation_doc on outils.mv5_evaluation using gin (doc);
explain (analyze, costs off)
select doc ->> 'inscriptionid' from outils.mv5_evaluation where doc @> '{"sessionid": 40}';
explain (analyze, costs off)
select doc ->> 'inscriptionid' from outils.mv5_evaluation where doc @@ '$.sessionid == 40';
-- The same filter written with ->> does not use it.
explain (analyze, costs off)
select doc ->> 'inscriptionid' from outils.mv5_evaluation where (doc ->> 'sessionid')::integer = 40;
drop index outils.mv5_evaluation_doc;

-- Changing a document: jsonb_set, || and -, in place of JSON_MODIFY.
select jsonb_set(doc, '{notes,animation}', '5') -> 'notes' as set_mark,
       (doc || '{"recommande": false}') ->> 'recommande' as merged,
       doc - 'themes' ? 'themes' as themes_left
from outils.mv5_evaluation
where evaluationid = 1;
