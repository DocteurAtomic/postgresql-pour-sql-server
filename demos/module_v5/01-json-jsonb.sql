-- Clip V5.1: json and jsonb. Lab database, psql.
-- Two statements fail on purpose: ON_ERROR_STOP is off around them.

-- The same text, typed json and jsonb: json keeps the text, jsonb parses it.
select '{"b": 1,   "a": 2, "a": 3}'::json  as as_json,
       '{"b": 1,   "a": 2, "a": 3}'::jsonb as as_jsonb;

-- A duplicate key: json keeps both pairs, and its functions read the last one.
select '{"b": 1, "a": 2, "a": 3}'::json ->> 'a'  as json_a,
       '{"b": 1, "a": 2, "a": 3}'::jsonb ->> 'a' as jsonb_a;

-- Equality: jsonb compares values, json has no equality operator.
select '{"a": 1, "b": [1, 2]}'::jsonb = '{"b": [1,2], "a": 1}'::jsonb as jsonb_equal;
\set ON_ERROR_STOP off
select '{"a": 1}'::json = '{"a": 1}'::json as json_equal;
select distinct doc::json from outils.mv5_evaluation;
\set ON_ERROR_STOP on

-- Any JSON value is accepted at the top, a scalar included.
select '42'::jsonb as a_number, '"texte"'::jsonb as a_string, 'null'::jsonb as a_json_null,
       jsonb_typeof('null'::jsonb) as its_type, 'null'::jsonb is null as is_sql_null;

-- Numbers keep their precision: jsonb stores them as numeric.
select '{"prix": 1250.10, "big": 12345678901234567890.5}'::jsonb as numbers;

-- Validation of a text before casting, the counterpart of ISJSON.
select 'not json' is json as text_is_json,
       '{"a": 1}' is json object as is_object,
       '[1, 2]' is json object as array_is_object;

-- Storage: the same documents as json text and as jsonb.
select pg_size_pretty(sum(pg_column_size(doc::text::json))) as as_json,
       pg_size_pretty(sum(pg_column_size(doc))) as as_jsonb
from outils.mv5_evaluation;
