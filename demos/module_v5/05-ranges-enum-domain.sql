-- Clip V5.5: ranges, exclusion constraints, enums and domains. Lab database, psql, after
-- 00-setup.sql (btree_gist). Several statements fail on purpose: ON_ERROR_STOP is off
-- around them. stage.session is only read: the constraint attempt is rolled back.

-- What duree means: for the sessions that have a room, the duration of the stage in days.
select (s.duree = st.duree) as same_as_stage, s.duree, count(*) as sessions
from stage.session as s
join stage.stage as st on st.stageid = s.stageid
where s.salleformationid is not null
group by 1, 2
order by 1, 2;
select count(*) filter (where duree > 5) as longer_than_5,
       count(*) filter (where duree > 5 and salleformationid is not null) as with_a_room
from stage.session;

-- A daterange built from datedebut and duree: the lower bound included, the upper excluded.
select sessionid, datedebut, duree,
       daterange(datedebut, datedebut + duree) as period,
       upper(daterange(datedebut, datedebut + duree)) as first_free_day
from stage.session
where sessionid in (764, 830);

-- Two sessions in the same room whose periods overlap (&&).
select count(*) as overlapping_pairs, count(distinct a.salleformationid) as rooms
from stage.session as a
join stage.session as b
  on b.salleformationid = a.salleformationid
 and b.sessionid > a.sessionid
 and daterange(a.datedebut, a.datedebut + a.duree) && daterange(b.datedebut, b.datedebut + b.duree);
select a.salleformationid as room, a.sessionid, a.datedebut, a.duree,
       b.sessionid as other, b.datedebut as other_start, b.duree as other_duree
from stage.session as a
join stage.session as b
  on b.salleformationid = a.salleformationid
 and b.sessionid > a.sessionid
 and daterange(a.datedebut, a.datedebut + a.duree) && daterange(b.datedebut, b.datedebut + b.duree)
order by a.datedebut
limit 3;

-- The exclusion constraint on the table as it is: refused, the data already breaks it.
begin;
\set ON_ERROR_STOP off
alter table stage.session
    add constraint mv5_session_no_overlap
    exclude using gist (salleformationid with =,
                        daterange(datedebut, datedebut + duree) with &&);
\set ON_ERROR_STOP on
rollback;

-- An enum for the status of a booking, and a booking table with the constraint.
create type outils.mv5_booking_status as enum ('option', 'confirmee', 'annulee');
create table outils.mv5_booking (
    bookingid integer generated always as identity primary key,
    salleformationid integer not null references reference.salleformation,
    period daterange not null,
    status outils.mv5_booking_status not null default 'option',
    exclude using gist (salleformationid with =, period with &&)
        where (status <> 'annulee')
);
insert into outils.mv5_booking (salleformationid, period, status) values
    (18, '[2026-11-02,2026-11-07)', 'confirmee'),
    (18, '[2026-11-09,2026-11-12)', 'option');
\set ON_ERROR_STOP off
-- Overlaps the first booking: refused.
insert into outils.mv5_booking (salleformationid, period) values (18, '[2026-11-05,2026-11-07)');
-- Not a value of the enum: refused.
insert into outils.mv5_booking (salleformationid, period, status) values (19, '[2026-11-02,2026-11-03)', 'Confirmee');
\set ON_ERROR_STOP on
-- Starts the day the first one ends ([) bounds): accepted. A cancelled booking does not count.
insert into outils.mv5_booking (salleformationid, period, status) values
    (18, '[2026-11-07,2026-11-09)', 'option'),
    (18, '[2026-11-03,2026-11-05)', 'annulee');
-- The enum sorts in the order of its declaration, not in alphabetical order.
select bookingid, period, status from outils.mv5_booking order by status, period;
-- Which booking holds the room on a given day: @> on the range, the index answers.
select bookingid, period from outils.mv5_booking
where salleformationid = 18 and period @> date '2026-11-04' and status <> 'annulee';
alter type outils.mv5_booking_status add value 'facturee' after 'confirmee';
select enum_range(null::outils.mv5_booking_status) as labels;

-- A domain: a type with its rule, reusable in every table.
create domain outils.mv5_percent as smallint not null default 0
    check (value between 0 and 100);
create table outils.mv5_discount (inscriptionid integer primary key, remise outils.mv5_percent);
insert into outils.mv5_discount values (1, 10);
\set ON_ERROR_STOP off
insert into outils.mv5_discount values (2, 150);
\set ON_ERROR_STOP on
\dD outils.*

drop table outils.mv5_discount;
drop domain outils.mv5_percent;
drop table outils.mv5_booking;
drop type outils.mv5_booking_status;
