-- ci: skip (T-SQL, plays on SQL Server)
-- Clip V4.5, SQL Server side, in MV4PgIndex (00-setup.sql). No skip scan: a condition on
-- the second column of (Relance, DateFacture) reads the whole index. The T-SQL workaround
-- lists the values of the first column, one seek per value.
SET NOCOUNT ON;
GO
SET SHOWPLAN_TEXT ON;
GO
SELECT FactureCd, Relance FROM dbo.Facture WHERE DateFacture = '20260312';
GO
SELECT FactureCd, Relance FROM dbo.Facture
WHERE Relance IN (0, 1, 2, 3) AND DateFacture = '20260312';
GO
SET SHOWPLAN_TEXT OFF;
GO
SET STATISTICS IO ON;
SELECT COUNT(*) AS invoices FROM dbo.Facture WHERE DateFacture = '20260312';
SELECT COUNT(*) AS invoices FROM dbo.Facture
WHERE Relance IN (0, 1, 2, 3) AND DateFacture = '20260312';
SET STATISTICS IO OFF;
SELECT index_id, page_count
FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID(N'dbo.Facture'), 2, NULL, 'LIMITED');
GO
