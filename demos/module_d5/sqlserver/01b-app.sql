-- ci: skip (T-SQL, scene played by scene.sh with 01a and 01c)
-- Clip D5.1, SQL Server side, session B (host md5-app): updates a row, then sqlcmd runs a
-- shell sleep and sends nothing. The session is sleeping, with an open transaction.
SET NOCOUNT ON;
BEGIN TRAN;
UPDATE dbo.Session SET Prix = Prix + 10 WHERE SessionId = 40;
GO
!! sleep 12
COMMIT;
GO
