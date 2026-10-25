-- ci: skip
-- Clip D5.1, session E of the scene: sampling the wait events, since PostgreSQL keeps no
-- cumulative wait statistics (pg_wait_sampling, an extension that is not in the lab, does).
-- Fifty samples of pg_stat_activity, one every 0.1 s, kept in a temporary table; each
-- sample starts with pg_stat_clear_snapshot(), see 01f-sampler-cached.sql.
set application_name = 'md5-sampler';
create temporary table md5_samples (n int, app text, wait text);
do $$
begin
    for i in 1..50 loop
        perform pg_stat_clear_snapshot();
        insert into md5_samples
        select i, application_name || case when leader_pid is null then '' else ' (worker)' end,
               case when state = 'active' then coalesce(wait_event_type || ':' || wait_event, 'CPU')
                    else state || ', ' || coalesce(wait_event, '-') end
        from pg_stat_activity
        where datname = current_database()
          and application_name in ('md5-report', 'md5-app', 'md5-idle');
        perform pg_sleep(0.1);
    end loop;
end $$;
select app, wait, count(*) as samples
from md5_samples
group by app, wait
order by app, samples desc;
