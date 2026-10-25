-- Clip D4.5, SQL Server side: SQL Server Agent and its jobs, stored in msdb. SQL Server
-- 2022 on Linux, container sql2022, sqlcmd. Read only.
set nocount on;
select servicename, status_desc, startup_type_desc from sys.dm_server_services;
select count(*) as jobs from msdb.dbo.sysjobs;
-- Maintenance plans are SSIS packages stored in msdb, run by Agent jobs.
select count(*) as maintenance_plans from msdb.dbo.sysmaintplan_plans;
