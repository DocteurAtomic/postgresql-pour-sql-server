-- Clip D4.4, SQL Server side: the usage counters of the indexes, emptied at every restart
-- of the instance, like the statistics of PostgreSQL after a restore. SQL Server 2022, base
-- PachaDataFormation, sqlcmd. Read only.
set nocount on;
select sqlserver_start_time from sys.dm_os_sys_info;
select top (6) object_schema_name(i.object_id) + '.' + object_name(i.object_id) as table_name,
       i.name as index_name, u.user_seeks, u.user_scans, u.user_lookups, u.user_updates
from sys.indexes as i
left join sys.dm_db_index_usage_stats as u
       on u.object_id = i.object_id and u.index_id = i.index_id and u.database_id = db_id()
where objectproperty(i.object_id, 'IsUserTable') = 1 and i.index_id > 0
order by isnull(u.user_seeks + u.user_scans + u.user_lookups, 0) desc;
-- Indexes never read since the restart.
select count(*) as indexes,
       sum(case when isnull(u.user_seeks + u.user_scans + u.user_lookups, 0) = 0 then 1 else 0 end)
         as never_read
from sys.indexes as i
left join sys.dm_db_index_usage_stats as u
       on u.object_id = i.object_id and u.index_id = i.index_id and u.database_id = db_id()
where objectproperty(i.object_id, 'IsUserTable') = 1 and i.index_id > 0;
