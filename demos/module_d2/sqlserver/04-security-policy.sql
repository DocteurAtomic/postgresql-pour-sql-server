-- Clip D2.4, SQL Server side: a filter predicate on Outils.Session, read from
-- SESSION_CONTEXT. Run after 03-schema-grant.sql, on your own SQL Server instance
-- (recorded on SQL Server 2022, sqlcmd, as sa). Dropped with the database by 99-cleanup.sql.
SET NOCOUNT ON;
USE MD2PgSecu;
GO
CREATE FUNCTION Outils.fn_FormateurSession (@FormateurId int)
RETURNS TABLE
WITH SCHEMABINDING
AS RETURN SELECT 1 AS ok
          WHERE @FormateurId = CAST(SESSION_CONTEXT(N'FormateurId') AS int);
GO
CREATE SECURITY POLICY Outils.md2_formateur
    ADD FILTER PREDICATE Outils.fn_FormateurSession(FormateurId) ON Outils.Session
    WITH (STATE = ON);
GO
-- sa is sysadmin, hence dbo: the policy filters it too.
SELECT USER_NAME() AS user_name, COUNT(*) AS rows_no_context FROM Outils.Session;
EXEC sys.sp_set_session_context @key = N'FormateurId', @value = 2;
SELECT COUNT(*) AS rows_formateur_2 FROM Outils.Session;
-- read_only = 1: the value cannot change until the end of the session.
EXEC sys.sp_set_session_context @key = N'FormateurId', @value = 3, @read_only = 1;
SELECT COUNT(*) AS rows_formateur_3 FROM Outils.Session;
GO
EXEC sys.sp_set_session_context @key = N'FormateurId', @value = 2;
GO
SELECT name, is_enabled, is_schema_bound FROM sys.security_policies;
