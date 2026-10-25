-- ci: skip (T-SQL, plays on SQL Server)
-- Clip V5.5, SQL Server side: no range type and no exclusion constraint. Two date columns,
-- a CHECK, and a trigger that looks for an overlap. Run after 00-setup.sql; writes only
-- in MV5PgDemo (sqlcmd).
USE MV5PgDemo;
GO
SET NOCOUNT ON;
CREATE TABLE dbo.Booking (
    BookingId int IDENTITY PRIMARY KEY,
    SalleFormationId int NOT NULL,
    DateDebut date NOT NULL,
    DateFin date NOT NULL,          -- excluded, as the upper bound of a daterange
    Status varchar(10) NOT NULL DEFAULT 'option'
        CONSTRAINT CK_Booking_Status CHECK (Status IN ('option', 'confirmee', 'annulee')),
    CONSTRAINT CK_Booking_Dates CHECK (DateFin > DateDebut)
);
GO
CREATE TRIGGER dbo.trg_Booking_NoOverlap ON dbo.Booking
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1
        FROM inserted AS i
        JOIN dbo.Booking AS b
          ON b.SalleFormationId = i.SalleFormationId
         AND b.BookingId <> i.BookingId
         AND b.DateDebut < i.DateFin
         AND i.DateDebut < b.DateFin
        WHERE i.Status <> 'annulee' AND b.Status <> 'annulee')
        THROW 50001, 'The room is already booked for these dates.', 1;
END;
GO
INSERT INTO dbo.Booking (SalleFormationId, DateDebut, DateFin, Status)
VALUES (18, '2026-11-02', '2026-11-07', 'confirmee'), (18, '2026-11-09', '2026-11-12', 'option');
GO
-- Overlaps the first booking: the trigger rolls the statement back.
INSERT INTO dbo.Booking (SalleFormationId, DateDebut, DateFin) VALUES (18, '2026-11-05', '2026-11-07');
GO
-- Starts the day the first one ends: accepted.
INSERT INTO dbo.Booking (SalleFormationId, DateDebut, DateFin) VALUES (18, '2026-11-07', '2026-11-09');
SELECT BookingId, SalleFormationId, DateDebut, DateFin, Status FROM dbo.Booking ORDER BY DateDebut;
GO
