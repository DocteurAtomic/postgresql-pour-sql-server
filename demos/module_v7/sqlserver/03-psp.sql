-- ci: skip (T-SQL, plays on SQL Server)
-- Clip V7.3, SQL Server side: the Parameter Sensitive Plan optimization of SQL Server 2022
-- (compatibility level 160). A dispatcher plan appears for dbo.Skewed, not for dbo.Facture.
SET NOCOUNT ON;
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
EXEC sys.sp_executesql N'SELECT COUNT(*) AS invoices FROM dbo.Facture WHERE Relance = @r', N'@r smallint', @r = 29;
EXEC sys.sp_executesql N'SELECT COUNT(*) AS invoices FROM dbo.Facture WHERE Relance = @r', N'@r smallint', @r = 0;
EXEC sys.sp_executesql N'SELECT COUNT(*) AS n, MAX(Filler) AS f FROM dbo.Skewed WHERE K = @k', N'@k int', @k = 5;
EXEC sys.sp_executesql N'SELECT COUNT(*) AS n, MAX(Filler) AS f FROM dbo.Skewed WHERE K = @k', N'@k int', @k = 0;
WITH XMLNAMESPACES (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
SELECT CASE WHEN st.text LIKE N'%dbo.Skewed%' THEN 'dbo.Skewed' ELSE 'dbo.Facture' END AS table_name,
       cp.usecounts,
       qp.query_plan.exist('//Dispatcher') AS dispatcher,
       qp.query_plan.value('(//ParameterSensitivePredicate/@LowBoundary)[1]', 'varchar(12)') AS low_boundary,
       qp.query_plan.value('(//ParameterSensitivePredicate/@HighBoundary)[1]', 'varchar(12)') AS high_boundary,
       qp.query_plan.value('(//QueryPlan/@QueryVariantID)[1]', 'varchar(5)') AS variant,
       qp.query_plan.query('for $r in //RelOp return string($r/@PhysicalOp)').value('.', 'varchar(120)') AS operators
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS st
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
WHERE st.dbid = DB_ID() AND st.text LIKE N'%WHERE % = @%' AND st.text NOT LIKE N'%dm_exec_cached_plans%'
ORDER BY table_name, variant;
GO
