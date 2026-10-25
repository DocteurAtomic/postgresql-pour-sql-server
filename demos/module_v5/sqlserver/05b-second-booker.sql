-- ci: skip (T-SQL, two sqlcmd sessions, after 05-booking-trigger.sql)
-- Clip V5.5, SQL Server side, session B: books an overlapping period of the same room while
-- A has not committed, then reads the table once A has committed. MV5PgDemo only. The cleanup is in its own batch: a THROW in the
-- trigger ends the batch of the INSERT.
USE MV5PgDemo;
SET NOCOUNT ON;
SELECT CONVERT(time(0), SYSDATETIME()) AS b_starts_at;
INSERT INTO dbo.Booking (SalleFormationId, DateDebut, DateFin) VALUES (18, '2026-12-03', '2026-12-06');
GO
SET NOCOUNT ON;
SELECT CONVERT(time(0), SYSDATETIME()) AS b_answered_at;
-- Once A has committed: the bookings of December.
WAITFOR DELAY '00:00:03';
SELECT BookingId, DateDebut, DateFin FROM dbo.Booking WHERE DateDebut >= '2026-12-01' ORDER BY BookingId;
DELETE FROM dbo.Booking WHERE DateDebut >= '2026-12-01';
GO
