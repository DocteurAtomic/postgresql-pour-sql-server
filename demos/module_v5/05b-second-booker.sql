-- ci: skip (two sessions: ./demos/module_v5/scene.sh demos/module_v5/05a-booker.sql demos/module_v5/05b-second-booker.sql)
-- Clip V5.5, session B, one second after A: books an overlapping period of the same room.
-- The insert waits for A, then fails; B drops the table at the end.
select clock_timestamp()::time(0) as b_starts_at;
\set ON_ERROR_STOP off
insert into outils.mv5_booking_race values (18, '[2026-12-03,2026-12-06)');
\set ON_ERROR_STOP on
select clock_timestamp()::time(0) as b_answered_at;
select count(*) as bookings from outils.mv5_booking_race;
drop table outils.mv5_booking_race;
