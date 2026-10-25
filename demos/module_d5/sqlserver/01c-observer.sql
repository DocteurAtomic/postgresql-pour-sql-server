-- ci: skip (T-SQL, scene played by scene.sh with 01a and 01b)
-- Clip D5.1, SQL Server side, session C: the DBA. sys.dm_exec_requests lists what runs;
-- the sleeping session with its open transaction is only in sys.dm_exec_sessions. Then KILL
-- of that session, found by its host name: only the sessions of the scene are touched.
SET NOCOUNT ON;
WAITFOR DELAY '00:00:02';
SELECT s.host_name, r.session_id, r.status, r.command, r.wait_type, r.wait_time,
       r.blocking_session_id, r.open_transaction_count, r.dop
FROM sys.dm_exec_requests r
JOIN sys.dm_exec_sessions s ON s.session_id = r.session_id
WHERE s.host_name LIKE N'md5-%' AND s.session_id <> @@SPID;
SELECT host_name, session_id, status, open_transaction_count,
       CASE WHEN status = N'sleeping'
            THEN DATEDIFF(s, last_request_end_time, SYSDATETIME()) END AS idle_s
FROM sys.dm_exec_sessions
WHERE host_name LIKE N'md5-%' AND session_id <> @@SPID
ORDER BY host_name;
SELECT COUNT(*) AS tasks_of_the_report
FROM sys.dm_os_tasks t
JOIN sys.dm_exec_sessions s ON s.session_id = t.session_id
WHERE s.host_name = N'md5-report';
DECLARE @spid int = (SELECT session_id FROM sys.dm_exec_sessions
                     WHERE host_name = N'md5-app' AND open_transaction_count > 0);
DECLARE @kill nvarchar(20) = N'KILL ' + CAST(@spid AS nvarchar(10));
EXEC (@kill);
WAITFOR DELAY '00:00:00.500';
SELECT host_name, session_id, status
FROM sys.dm_exec_sessions
WHERE host_name LIKE N'md5-%' AND session_id <> @@SPID
ORDER BY host_name;
SELECT Prix FROM dbo.Session WHERE SessionId = 40;
GO
