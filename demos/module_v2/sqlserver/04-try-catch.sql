-- ci: skip (T-SQL, plays on SQL Server)
-- Clip V2.4, SQL Server side: TRY ... CATCH does not roll back the work of the TRY block.
-- Run after 00-setup.sql; writes only in MV2PgDemo (sqlcmd).
USE MV2PgDemo;
SET NOCOUNT ON;
BEGIN TRY
    INSERT INTO dbo.Log VALUES (2, 'inside TRY');
    INSERT INTO dbo.Log VALUES (1, 'duplicate');
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS error_number, ERROR_MESSAGE() AS message,
           XACT_STATE() AS xact_state;
END CATCH;
SELECT Id, Label FROM dbo.Log ORDER BY Id;
DELETE FROM dbo.Log WHERE Id = 2;
GO
