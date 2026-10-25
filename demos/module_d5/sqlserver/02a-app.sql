-- ci: skip (T-SQL, scene played by scene.sh with 02b to 02d)
-- Clip D5.2, SQL Server side, session A (host md5-app): updates session 40 and forgets its
-- transaction, sleeping during the shell sleep. The observer KILLs it.
SET NOCOUNT ON;
BEGIN TRAN;
UPDATE dbo.Session SET Prix = Prix + 10 WHERE SessionId = 40;
GO
!! sleep 15
COMMIT;
GO
