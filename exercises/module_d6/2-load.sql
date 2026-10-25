-- ci: skip (exercise D6, runs on pgd6-exercise-primary)
-- A burst of writes, about 160 MB of WAL: a table of 300,000 wide rows. Run it on the
-- primary, as many times as you like; 9-stop.sh removes the containers and the tables.
drop table if exists outils.md6x_load;
create table outils.md6x_load as
select g, repeat('x', 500) as filler
from generate_series(1, 300000) g;
