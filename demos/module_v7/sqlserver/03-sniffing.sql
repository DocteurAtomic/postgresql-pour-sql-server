-- ci: skip (T-SQL, plays on SQL Server)
-- Clip V7.3, SQL Server side: parameter sniffing on dbo.Facture of MV7PgSniff
-- (00-setup.sql), with sp_executesql as a driver sends it. sqlcmd -I.
SET NOCOUNT ON;
-- Empties the plan cache of this database only.
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
SET STATISTICS IO ON;
DECLARE @sql nvarchar(400) = N'SELECT COUNT(*) AS invoices, SUM(MontantTTC) AS amount
FROM dbo.Facture WHERE Relance = @r';
-- First execution with a rare value: the plan is compiled for it, then reused for 0.
EXEC sys.sp_executesql @sql, N'@r smallint', @r = 29;
EXEC sys.sp_executesql @sql, N'@r smallint', @r = 0;
-- The density instead of the value, like the generic plan of PostgreSQL.
EXEC sys.sp_executesql N'SELECT COUNT(*) AS invoices, SUM(MontantTTC) AS amount
FROM dbo.Facture WHERE Relance = @r OPTION (OPTIMIZE FOR UNKNOWN)', N'@r smallint', @r = 0;
-- A plan for each execution, like a custom plan.
EXEC sys.sp_executesql N'SELECT COUNT(*) AS invoices, SUM(MontantTTC) AS amount
FROM dbo.Facture WHERE Relance = @r OPTION (RECOMPILE)', N'@r smallint', @r = 0;
SET STATISTICS IO OFF;
-- What the plan cache keeps: one plan per text, shared by every session.
WITH XMLNAMESPACES (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
SELECT cp.objtype, cp.usecounts,
       qp.query_plan.value('(//ColumnReference[@Column="@r"]/@ParameterCompiledValue)[1]', 'varchar(10)') AS compiled_for,
       qp.query_plan.value('(//RelOp[@PhysicalOp="Index Seek" or @PhysicalOp="Clustered Index Scan"]/@EstimateRows)[1]', 'varchar(10)') AS estimated_rows,
       qp.query_plan.query('for $r in //RelOp return string($r/@PhysicalOp)').value('.', 'varchar(120)') AS operators,
       CASE WHEN st.text LIKE N'%OPTIMIZE FOR UNKNOWN%' THEN 'OPTIMIZE FOR UNKNOWN' ELSE '' END AS hint
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS st
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
WHERE st.dbid = DB_ID() AND st.text LIKE N'%dbo.Facture WHERE Relance = @r%'
  AND st.text NOT LIKE N'%dm_exec_cached_plans%'
ORDER BY cp.usecounts DESC;
GO
