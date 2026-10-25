-- Clip 4.4: numbers and booleans. Lab database, psql.
-- Three statements fail on purpose: ON_ERROR_STOP is off around them.

-- Integer division, as in SQL Server.
select 7 / 2 as integer_division, 7 / 2.0 as numeric_division, 7 % 2 as modulo;

-- avg() of an integer column returns numeric; SQL Server's AVG returns int.
select avg(duree) as avg_days, pg_typeof(avg(duree)) as avg_type,
       pg_typeof(sum(duree)) as sum_type, pg_typeof(count(*)) as count_type
from stage.stage;

-- No tinyint: the port turned SQL Server's tinyint into smallint.
\set ON_ERROR_STOP off
select 32767::smallint + 1::smallint;
select 2147483647 + 1;
\set ON_ERROR_STOP on
select 2147483647::bigint + 1 as with_bigint;

-- numeric is exact, float is not.
select 0.1 + 0.2 as numeric_sum,
       0.1::double precision + 0.2::double precision as float_sum,
       1 / 3::numeric as numeric_third;

-- reference.ville.codeinsee: a float in SQL Server, a real in the port. The code 01001 became 1001.
select nomville, codepostal, codeinsee, pg_typeof(codeinsee) as type
from reference.ville
order by villeid
limit 3;
select count(*) as insee_codes_below_10000
from reference.ville
where codeinsee < 10000;
-- Corsica: 2A004 and 2B033 in the official code, an old numeric code here.
select nomville, codeinsee
from reference.ville
where nomville in ('Ajaccio', 'Bastia')
order by nomville;

-- money exists, and depends on lc_monetary.
show lc_monetary;
select 1234.5::money as amount;

-- bit becomes boolean, and boolean is not a number.
\set ON_ERROR_STOP off
select count(*) from inscription.inscription where present = 1;
\set ON_ERROR_STOP on
select count(*) filter (where present) as present,
       sum(present::integer) as present_sum,
       count(*) as enrollments
from inscription.inscription;
select 't'::boolean as t, 'yes'::boolean as yes, 'off'::boolean as off, 1::boolean as one;
