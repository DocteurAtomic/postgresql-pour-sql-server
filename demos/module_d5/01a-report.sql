-- ci: skip
-- Clip D5.1, session A of the scene played by ../module_03/scene.sh with 01b to 01f.
-- A long report: 926 million rows of a cross join, run by a leader and a parallel worker.
-- The observer (01d) cancels it after about seven seconds; the session stays.
set application_name = 'md5-report';
\timing on
select count(*)
from inscription.inscription a
cross join inscription.inscription b
where a.contactid + b.contactid < 0;
-- After the cancel, the session stays connected, idle.
\! sleep 4
