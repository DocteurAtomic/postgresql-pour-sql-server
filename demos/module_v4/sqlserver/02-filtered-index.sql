-- ci: skip (T-SQL, plays on SQL Server)
-- Clip V4.2, SQL Server side, in MV4PgIndex (00-setup.sql). A filtered index on the
-- invoices sent a reminder: a literal uses it, a parameter does not, and the cached plan
-- of the parameterized query lists the index under UnmatchedIndexes.
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;   -- required by a filtered index; sqlcmd sets it OFF
-- The index (Relance, DateFacture) of 00-setup.sql is set aside, then recreated at the end.
DROP INDEX IX_Facture_Relance_DateFacture ON dbo.Facture;
CREATE INDEX FIX_Facture_Reminded ON dbo.Facture (DateFacture) WHERE Relance > 0;
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;   -- this database only
GO
SET STATISTICS IO ON;
SELECT COUNT(*) AS literal FROM dbo.Facture WHERE Relance > 0 AND DateFacture = '20260312';
EXEC sys.sp_executesql
    N'SELECT COUNT(*) AS parameter FROM dbo.Facture WHERE Relance > @r AND DateFacture = ''20260312'';',
    N'@r smallint', @r = 0;
SET STATISTICS IO OFF;
GO
SELECT qp.query_plan.exist('//*:UnmatchedIndexes') AS unmatched_indexes,
       qp.query_plan.value('(//*:IndexScan/*:Object/@Index)[1]', 'sysname') AS index_used
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp
WHERE st.text LIKE N'(@r smallint)%' AND qp.dbid = DB_ID();   -- the parameterized statement
GO
DROP INDEX FIX_Facture_Reminded ON dbo.Facture;
CREATE INDEX IX_Facture_Relance_DateFacture ON dbo.Facture (Relance, DateFacture);
GO
