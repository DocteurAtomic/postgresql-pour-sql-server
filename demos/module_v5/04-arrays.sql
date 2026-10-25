-- Clip V5.4: arrays. Lab database, psql.
-- Two statements fail on purpose: ON_ERROR_STOP is off around them.

-- Two ways to write an array; the first element is number 1.
select '{40,90,887}'::integer[] as literal,
       array[40, 90, 887] as constructor,
       (array[40, 90, 887])[1] as first_element,
       (array[40, 90, 887])[4] as out_of_range,
       (array[40, 90, 887])[2:3] as slice,
       cardinality(array[40, 90, 887]) as elements;

-- A list of values as one parameter: = ANY, in place of STRING_SPLIT or a table-valued
-- parameter.
prepare sessions_by_id(integer[]) as
select sessionid, datedebut, salleformationid
from stage.session
where sessionid = any ($1)
order by sessionid;
execute sessions_by_id('{40,90,887}');
-- An empty list is a valid parameter; an empty IN list is a syntax error.
execute sessions_by_id('{}');
\set ON_ERROR_STOP off
select sessionid from stage.session where sessionid in ();
\set ON_ERROR_STOP on
deallocate sessions_by_id;

-- unnest turns the array into rows, WITH ORDINALITY numbers them.
select u.sessionid, u.position
from unnest('{887,40,90}'::integer[]) with ordinality as u (sessionid, position);

-- array_agg builds one: the contacts of each session, in an array column. DISTINCT: the
-- port holds 5,000 (sessionid, contactid) pairs entered twice.
create table outils.mv5_session_contacts as
select sessionid, array_agg(distinct contactid order by contactid) as contacts
from inscription.inscription
where sessionid in (40, 90, 887)
group by sessionid;
select sessionid, contacts, cardinality(contacts) as inscriptions
from outils.mv5_session_contacts
order by sessionid;

-- Searching inside: = ANY on the column, @> (contains), && (overlaps).
select sessionid from outils.mv5_session_contacts where 8049 = any (contacts);
select sessionid from outils.mv5_session_contacts where contacts @> '{8049}';
select sessionid from outils.mv5_session_contacts where contacts && '{241,7463}';

-- What the table checked and the array does not: the elements have no foreign key.
\set ON_ERROR_STOP off
insert into inscription.inscription (sessionid, contactid) values (40, 999999);
\set ON_ERROR_STOP on
update outils.mv5_session_contacts
set contacts = contacts || 999999
where sessionid = 40;
select sessionid, contacts[cardinality(contacts)] as last_contact
from outils.mv5_session_contacts
where sessionid = 40;

drop table outils.mv5_session_contacts;
