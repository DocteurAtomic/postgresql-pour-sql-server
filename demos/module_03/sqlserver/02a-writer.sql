-- ci: skip (T-SQL, two sessions on SQL Server)
-- Clip 3.2, SQL Server side, session A: the same writer as 02a-writer.sql on PostgreSQL.
-- Start session B (02b-reader.sql) one second after this one.
USE M03PgRcsi;
SET NOCOUNT ON;
UPDATE dbo.Session SET Prix = 2500 WHERE SessionId = 40;
BEGIN TRAN;
UPDATE dbo.Session SET Prix = 2900 WHERE SessionId = 40;
WAITFOR DELAY '00:00:06';
COMMIT;
GO
