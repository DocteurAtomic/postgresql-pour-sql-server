-- ci: skip
-- Clip D5.1, session F of the scene: the same loop as 01e, without pg_stat_clear_snapshot().
-- The first read of pg_stat_activity is kept until the end of the transaction, and a DO
-- block is one transaction: the fifty samples are the same, before and after the observer
-- cancels and terminates.
set application_name = 'md5-sampler-cached';
create temporary table md5_samples (n int, app text, state text);
do $$
begin
    for i in 1..50 loop
        insert into md5_samples
        select i, application_name, state
        from pg_stat_activity
        where datname = current_database() and backend_type = 'client backend'
          and application_name in ('md5-report', 'md5-app', 'md5-idle');
        perform pg_sleep(0.1);
    end loop;
end $$;
select app, state, count(*) as samples
from md5_samples
group by app, state
order by app, samples desc;
