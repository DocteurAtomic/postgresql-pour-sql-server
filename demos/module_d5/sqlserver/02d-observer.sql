-- ci: skip (T-SQL, scene played by scene.sh with 02a to 02c)
-- Clip D5.2, SQL Server side, session D: the DBA. blocking_session_id in
-- sys.dm_exec_requests, then the head blocker, a session absent from the requests since it
-- runs nothing, and KILL on it, found by its host name.
SET NOCOUNT ON;
WAITFOR DELAY '00:00:02';
SELECT s.host_name, r.session_id, r.status, r.wait_type, r.wait_resource, r.blocking_session_id
FROM sys.dm_exec_requests r
JOIN sys.dm_exec_sessions s ON s.session_id = r.session_id
WHERE s.host_name LIKE N'md5-%' AND s.session_id <> @@SPID
ORDER BY r.session_id;
WITH blocked AS (
    SELECT session_id, blocking_session_id FROM sys.dm_exec_requests
    WHERE blocking_session_id <> 0
), heads AS (
    SELECT DISTINCT b.blocking_session_id AS session_id FROM blocked b
    WHERE b.blocking_session_id NOT IN (SELECT session_id FROM blocked)
)
SELECT s.host_name, h.session_id, s.status, s.open_transaction_count,
       DATEDIFF(s, s.last_request_end_time, SYSDATETIME()) AS idle_s,
       (SELECT COUNT(*) FROM sys.dm_exec_requests r WHERE r.session_id = h.session_id) AS in_requests
FROM heads h
JOIN sys.dm_exec_sessions s ON s.session_id = h.session_id;
SELECT SUBSTRING(t.text, CHARINDEX(N'BEGIN TRAN', t.text), 70) AS last_batch
FROM sys.dm_exec_connections c
CROSS APPLY sys.dm_exec_sql_text(c.most_recent_sql_handle) t
JOIN sys.dm_exec_sessions s ON s.session_id = c.session_id
WHERE s.host_name = N'md5-app';
DECLARE @spid int = (SELECT session_id FROM sys.dm_exec_sessions
                     WHERE host_name = N'md5-app' AND open_transaction_count > 0);
DECLARE @kill nvarchar(20) = N'KILL ' + CAST(@spid AS nvarchar(10));
EXEC (@kill);
GO
