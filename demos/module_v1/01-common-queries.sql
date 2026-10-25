-- Clip V1.1: the everyday T-SQL constructs and their PostgreSQL spelling. Lab database, psql.
-- Read only. Five statements fail on purpose: ON_ERROR_STOP is off around them.

-- TOP does not exist: LIMIT, or the standard FETCH FIRST.
\set ON_ERROR_STOP off
select top 3 sessionid from stage.session;
\set ON_ERROR_STOP on
select sessionid, note from stage.session order by note desc, sessionid limit 3;

-- NULL sorts as the largest value: first in a descending sort. NULLS LAST puts it back.
select sessionid, note from stage.session order by note desc nulls last, sessionid limit 3;

-- WITH TIES needs an ORDER BY, and returns the rows that tie with the last one.
\set ON_ERROR_STOP off
select stageid from stage.session fetch first 4 rows with ties;
\set ON_ERROR_STOP on
select stageid, count(*) as sessions
from stage.session
group by stageid
order by sessions desc
fetch first 4 rows with ties;

-- ISNULL and IIF are not functions here: COALESCE and CASE.
\set ON_ERROR_STOP off
select isnull(note, 0) from stage.session limit 1;
select iif(intraentrerprise, 'intra', 'inter') from stage.session limit 1;
\set ON_ERROR_STOP on
select sessionid, note isnull as note_is_null, coalesce(note, 0) as note,
       case when intraentrerprise then 'intra' else 'inter' end as kind
from stage.session
where sessionid in (42, 1784)
order by sessionid;

-- COALESCE takes the type of all its arguments; ISNULL in SQL Server takes the first one's.
select coalesce(null::varchar(2), 'abcdef') as with_coalesce;

-- GETDATE(): now() is a timestamptz, frozen at the start of the transaction (module 4).
select pg_typeof(now()) as now_type, pg_typeof(localtimestamp) as localtimestamp_type;

-- LEN ignores trailing spaces, length counts them; DATALENGTH is octet_length.
select length('abc  ') as length, length(rtrim('abc  ')) as like_len,
       octet_length('Élise') as bytes;

-- + does not concatenate strings: || (module 4 covers || and NULL, and concat).
\set ON_ERROR_STOP off
select nom + ' ' + prenom from contact.contact limit 1;
\set ON_ERROR_STOP on
select nom || ' ' || prenom as full_name from contact.contact order by contactid limit 1;

-- DATEADD and DATEDIFF: arithmetic on dates, and interval.
select date '2026-10-25' + 30 as plus_30_days,
       date '2026-01-31' + interval '1 month' as plus_1_month,
       (date '2026-01-31' + interval '1 month')::date as back_to_date,
       date '2026-12-31' - date '2026-01-01' as days_between;
