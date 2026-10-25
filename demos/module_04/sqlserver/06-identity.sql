-- Clip 4.6, SQL Server side: NEWID() anywhere, NEWSEQUENTIALID() only in a DEFAULT.
-- Read only (recorded on SQL Server 2022, sqlcmd). The second batch fails on purpose.
SET NOCOUNT ON;
SELECT NEWID() AS newid;
GO
SELECT NEWSEQUENTIALID() AS newsequentialid;
GO
