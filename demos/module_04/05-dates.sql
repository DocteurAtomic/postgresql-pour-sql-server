-- Clip 4.5: dates and times. Lab database, psql.
-- It runs pg_sleep(1) inside a transaction to show that now() does not move.

-- The microsecond: a seventh decimal digit is rounded.
select '2026-10-20 09:00:00.1234567'::timestamp as six_digits;

-- timestamptz stores an instant in UTC, and shows it in the session time zone.
show timezone;
select '2026-10-20 09:00:00+05:30'::timestamptz as entered_in_india,
       '2026-10-20 09:00:00+05:30'::timestamptz = '2026-10-20 03:30:00+00'::timestamptz as same_instant;
set timezone = 'Europe/Paris';
select '2026-10-20 09:00:00+05:30'::timestamptz as shown_in_paris;
reset timezone;

-- timestamp (without time zone) silently drops the offset.
select '2026-10-20 09:00:00+05:30'::timestamp as offset_dropped;
select pg_column_size(now()) as timestamptz_bytes, pg_column_size(current_date) as date_bytes;

-- now() is the start of the transaction; clock_timestamp() moves.
begin;
select now() as now_1, clock_timestamp() as clock_1;
select pg_sleep(1);
select now() as now_2, clock_timestamp() as clock_2;
commit;

-- Date arithmetic: integers of days and intervals.
select date '2026-10-20' + 30 as plus_30_days,
       date '2026-01-31' + interval '1 month' as plus_one_month,
       date '2026-12-25' - date '2026-10-20' as days_between;

-- date_trunc returns a timestamp: cast it back to date.
select date_trunc('month', datedebut)::date as month, count(*) as sessions
from stage.session
where datedebut >= '2019-01-01' and datedebut < '2019-04-01'
group by 1
order by 1;
select extract(year from datedebut) as year, count(*) as sessions
from stage.session
group by 1
order by 1;

-- The port keeps a calendar table, outils.tallydate; generate_series builds one on the fly.
select count(*) as days, min(jour), max(jour) from outils.tallydate;
select d::date as day, to_char(d, 'TMDay') as weekday
from generate_series(date '2026-10-19', date '2026-10-25', interval '1 day') as d;
