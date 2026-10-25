-- Clip D1.2: the settings of the instance and when a change takes effect. Lab database,
-- psql. Read only: every change of this clip runs in 02-alter-system.sh.

-- 400 settings, grouped by context: when a new value is taken into account.
select context, count(*) as settings
from pg_settings
group by context
order by settings desc;

-- One setting of each context we meet in the course.
select name, setting, unit, context
from pg_settings
where name in ('data_checksums', 'shared_buffers', 'max_connections', 'log_min_duration_statement',
               'autovacuum_naptime', 'work_mem', 'random_page_cost')
order by context, name;

-- Where each value that is not a built-in default comes from.
select name, setting, source, sourceline
from pg_settings
where source not in ('default', 'override', 'client')
order by source, name;

-- What the configuration files contain right now, and whether it was applied.
select sourceline, name, setting, applied, error
from pg_file_settings
order by seqno;
