-- Clip 4.7: conversions. Lab database, psql.
-- Six statements fail on purpose: ON_ERROR_STOP is off around them.

-- Three ways to write a cast.
select cast('42' as integer) as with_cast, '42'::integer as with_colons, integer '42' as typed_literal;

-- A quoted literal has no type yet: it takes the type of the column.
select count(*) as sessions from stage.session where sessionid = '45';

-- A text value is not compared with an integer, and no function takes an integer for a text.
\set ON_ERROR_STOP off
select count(*) from stage.session where sessionid = '45'::text;
select length(12345);
select count(*) from inscription.facture where facturecd = 123;
\set ON_ERROR_STOP on
select length(12345::text) as explicit_cast, 'Session ' || 13 as concatenation;

-- Casting a decimal to an integer rounds; SQL Server truncates.
select 3.7::integer as three_point_seven, 2.5::integer as two_point_five,
       (-3.5)::integer as minus_three_point_five, trunc(3.7)::integer as with_trunc;

-- No TRY_CAST: a bad value is an error; pg_input_is_valid() tests it first.
\set ON_ERROR_STOP off
select '42abc'::integer;
\set ON_ERROR_STOP on
select pg_input_is_valid('42abc', 'integer') as bad, pg_input_is_valid('42', 'integer') as good;

-- Dates: DateStyle reads month before day; to_char and to_date replace the CONVERT styles.
show datestyle;
\set ON_ERROR_STOP off
select '20/10/2026'::date;
select to_date('31/02/2026', 'DD/MM/YYYY');
\set ON_ERROR_STOP on
select to_char(date '2026-10-20', 'DD/MM/YYYY') as style_103,
       to_date('20/10/2026', 'DD/MM/YYYY') as parsed_103,
       to_char(timestamp '2026-10-20 09:05:00', 'YYYY-MM-DD"T"HH24:MI:SS') as style_126;

-- Back to the INSEE code: a real, then an integer, then a text of five digits.
select nomville, codeinsee, lpad(codeinsee::integer::text, 5, '0') as code_insee
from reference.ville
order by villeid
limit 3;
