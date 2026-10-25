-- ci: skip (two sessions: ./demos/module_v5/scene.sh demos/module_v5/05a-booker.sql demos/module_v5/05b-second-booker.sql)
-- Clip V5.5, session A: books room 18 and keeps its transaction open three seconds.
create table outils.mv5_booking_race (
    salleformationid integer not null,
    period daterange not null,
    exclude using gist (salleformationid with =, period with &&)
);
begin;
insert into outils.mv5_booking_race values (18, '[2026-12-01,2026-12-05)');
select pg_sleep(3);
commit;
select clock_timestamp()::time(0) as a_committed_at;
