-- Clip D2.1, SQL Server side: a login for the instance, a user in each database.
-- Run after 00-setup.sql, on your own SQL Server instance (recorded on SQL Server 2022,
-- sqlcmd, as sa).
SET NOCOUNT ON;
USE MD2PgSecu;
GO
-- The login exists, the database does not know it yet.
EXECUTE AS LOGIN = N'md2_app';
SELECT SUSER_SNAME() AS login_name, HAS_DBACCESS(N'MD2PgSecu') AS has_db_access;
REVERT;
GO
CREATE USER md2_app FOR LOGIN md2_app;
CREATE USER md2_analyste FOR LOGIN md2_analyste;
ALTER ROLE db_datareader ADD MEMBER md2_analyste;
EXECUTE AS LOGIN = N'md2_app';
SELECT SUSER_SNAME() AS login_name, USER_NAME() AS user_name, HAS_DBACCESS(N'MD2PgSecu') AS has_db_access;
REVERT;
GO
-- Two catalogs: sys.server_principals for the instance, sys.database_principals per database.
SELECT sp.name AS login_name, dp.name AS user_name, dp.type_desc
FROM sys.server_principals AS sp
LEFT JOIN sys.database_principals AS dp ON dp.sid = sp.sid
WHERE sp.name LIKE N'md2[_]%'
ORDER BY sp.name;
-- db_datareader is a role of this database only: the same login reads nothing elsewhere.
EXECUTE AS LOGIN = N'md2_analyste';
SELECT IS_ROLEMEMBER(N'db_datareader') AS datareader_here,
       HAS_DBACCESS(N'PachaDataFormation') AS access_to_pachadataformation,
       IS_SRVROLEMEMBER(N'sysadmin') AS is_sysadmin;
REVERT;
GO
