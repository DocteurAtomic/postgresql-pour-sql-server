-- Clip 5.5, SQL Server side. sql2022, database PachaDataFormation, sqlcmd.
-- Reads only; the two executions add a plan to the plan cache of the instance.
-- The same parameterized query with two values: one plan, compiled for the first
-- value, cached for the whole instance and reused by any session.
-- A replay first evicts the plan of the previous run, and only that one.
SET NOCOUNT ON;
DECLARE @h varbinary(64);
SELECT @h = cp.plan_handle
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS t
WHERE t.text LIKE N'%Relance = @r /* m05 */%' AND t.text NOT LIKE N'%dm_exec_cached_plans%';
IF @h IS NOT NULL DBCC FREEPROCCACHE (@h) WITH NO_INFOMSGS;

EXEC sys.sp_executesql
  N'SELECT COUNT(*) AS invoices FROM Inscription.Facture WHERE Relance = @r /* m05 */',
  N'@r smallint', @r = 2;
EXEC sys.sp_executesql
  N'SELECT COUNT(*) AS invoices FROM Inscription.Facture WHERE Relance = @r /* m05 */',
  N'@r smallint', @r = 0;

SELECT cp.objtype, cp.usecounts, cp.size_in_bytes
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS t
WHERE t.text LIKE N'%Relance = @r /* m05 */%' AND t.text NOT LIKE N'%dm_exec_cached_plans%';
