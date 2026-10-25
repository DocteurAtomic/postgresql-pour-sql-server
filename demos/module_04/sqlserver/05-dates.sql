-- Clip 4.5, SQL Server side: datetimeoffset keeps the offset; SYSDATETIME() moves in a transaction.
-- Read only (recorded on SQL Server 2022, sqlcmd). The transaction reads nothing and writes nothing.
SET NOCOUNT ON;
SELECT CAST('2026-10-20 09:00:00 +05:30' AS datetimeoffset(0)) AS entered_in_india,
       CASE WHEN CAST('2026-10-20 09:00:00 +05:30' AS datetimeoffset) = CAST('2026-10-20 03:30:00 +00:00' AS datetimeoffset)
            THEN 'equal' ELSE 'different' END AS same_instant;
SELECT CAST('2026-10-20 09:00:00.1234567' AS datetime2) AS seven_digits;

BEGIN TRANSACTION;
SELECT SYSDATETIME() AS t1;
WAITFOR DELAY '00:00:01';
SELECT SYSDATETIME() AS t2;
COMMIT;
