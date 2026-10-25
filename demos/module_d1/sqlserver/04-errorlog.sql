-- Clip D1.4, SQL Server side: the error log, read from T-SQL.
-- Read only, on any SQL Server instance (recorded on SQL Server 2022, sqlcmd).
SET NOCOUNT ON;
SELECT SERVERPROPERTY('ErrorLogFileName') AS error_log_file;

-- sp_readerrorlog: log number (0 = current), product (1 = SQL Server), text to search for.
EXEC sys.sp_readerrorlog 0, 1, N'Server process ID';
EXEC sys.sp_readerrorlog 0, 1, N'Recovery is complete';
