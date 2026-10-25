-- Module D2, SQL Server side, cleanup: drops the database MD2PgSecu and the md2_* logins.
-- On your own SQL Server instance (recorded on SQL Server 2022, sqlcmd, as sa).
SET NOCOUNT ON;
USE master;
GO
ALTER DATABASE MD2PgSecu SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE MD2PgSecu;
DROP LOGIN md2_app;
DROP LOGIN md2_analyste;
GO
SELECT COUNT(*) AS md2_logins FROM sys.server_principals WHERE name LIKE N'md2[_]%';
SELECT COUNT(*) AS md2_databases FROM sys.databases WHERE name = N'MD2PgSecu';
