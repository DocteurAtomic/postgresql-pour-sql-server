-- ci: skip (two sessions: play it one second after 05a-old-snapshot.sql, see scene.sh)
-- Clip 3.5, session B: VACUUM cannot remove the dead tuples that A's snapshot may still
-- need to see, until A ends.
update outils.m03_session set prix = prix;
vacuum outils.m03_session;
select dead_tuple_count from pgstattuple('outils.m03_session');

-- The session that holds the horizon back: the oldest backend_xmin.
select pid, state, backend_xmin, age(backend_xmin) as xmin_age,
       now() - xact_start as xact_age
from pg_stat_activity
where datname = current_database() and backend_xmin is not null
  and pid <> pg_backend_pid()
order by age(backend_xmin) desc;

select pg_sleep(8);                       -- A commits meanwhile
vacuum outils.m03_session;
select dead_tuple_count from pgstattuple('outils.m03_session');
