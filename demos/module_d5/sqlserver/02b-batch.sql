-- ci: skip (T-SQL, scene played by scene.sh with 02a, 02c and 02d)
-- Clip D5.2, SQL Server side, session B (host md5-batch): raises the prices of the stage
-- of session 40, waits for A, and is rolled back at the end.
SET NOCOUNT ON;
DECLARE @t0 datetime2 = SYSDATETIME();
BEGIN TRAN;
UPDATE dbo.Session SET Prix = Prix * 1.05
WHERE StageId = (SELECT StageId FROM dbo.Session WHERE SessionId = 40);
SELECT @@ROWCOUNT AS updated, DATEDIFF(ms, @t0, SYSDATETIME()) AS waited_ms;
ROLLBACK;
GO
