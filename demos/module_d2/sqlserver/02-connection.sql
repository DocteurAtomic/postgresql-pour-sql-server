-- Clip D2.2, SQL Server side: how this connection was authenticated and encrypted.
-- Read only, on any SQL Server instance (recorded on SQL Server 2022, sqlcmd 18, as sa).
SET NOCOUNT ON;
-- 0: mixed mode, SQL Server logins accepted; 1: Windows authentication only.
SELECT SERVERPROPERTY('IsIntegratedSecurityOnly') AS windows_only;
SELECT auth_scheme, encrypt_option, net_transport
FROM sys.dm_exec_connections
WHERE session_id = @@SPID;
