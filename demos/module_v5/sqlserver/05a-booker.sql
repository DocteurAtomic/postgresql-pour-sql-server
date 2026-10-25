-- ci: skip (T-SQL, two sqlcmd sessions, after 05-booking-trigger.sql)
-- Clip V5.5, SQL Server side, session A: books room 18 and keeps its transaction open three
-- seconds. Session B (05b-second-booker.sql) starts one second later. MV5PgDemo only.
USE MV5PgDemo;
SET NOCOUNT ON;
BEGIN TRAN;
INSERT INTO dbo.Booking (SalleFormationId, DateDebut, DateFin) VALUES (18, '2026-12-01', '2026-12-05');
WAITFOR DELAY '00:00:03';
COMMIT;
SELECT CONVERT(time(0), SYSDATETIME()) AS a_committed_at;
GO
