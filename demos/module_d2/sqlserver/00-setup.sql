-- Module D2, SQL Server side, setup: a database of its own, MD2PgSecu, a copy of
-- Stage.Session and two logins. Run on your own SQL Server instance (recorded on SQL Server
-- 2022, sqlcmd, as sa), never on a production server; 99-cleanup.sql drops everything.
-- The passwords are demonstration values.
SET NOCOUNT ON;
CREATE DATABASE MD2PgSecu;
GO
USE MD2PgSecu;
GO
CREATE SCHEMA Outils;
GO
SELECT SessionId, StageId, DateDebut, Prix, FormateurId
INTO Outils.Session
FROM PachaDataFormation.Stage.Session;
CREATE LOGIN md2_app WITH PASSWORD = N'Demo-App-2026!', DEFAULT_DATABASE = MD2PgSecu;
CREATE LOGIN md2_analyste WITH PASSWORD = N'Demo-Analyste-2026!', DEFAULT_DATABASE = MD2PgSecu;
SELECT name, type_desc FROM sys.server_principals WHERE name LIKE N'md2[_]%' ORDER BY name;
