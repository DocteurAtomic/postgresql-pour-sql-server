-- Clip D2.3, SQL Server side: a permission on the schema covers the tables created later.
-- Run after 01-principals.sql, on your own SQL Server instance (recorded on SQL Server
-- 2022, sqlcmd, as sa). Creates Outils.Tarif, dropped with the database by 99-cleanup.sql.
SET NOCOUNT ON;
USE MD2PgSecu;
GO
CREATE ROLE md2_lecture;
ALTER ROLE md2_lecture ADD MEMBER md2_app;
GRANT SELECT ON SCHEMA::Outils TO md2_lecture;
GO
CREATE TABLE Outils.Tarif (StageId int, Prix numeric(8,2));
GO
EXECUTE AS LOGIN = N'md2_app';
SELECT COUNT(*) AS tarif_rows FROM Outils.Tarif;
REVERT;
GO
-- The permission is held by the schema, not by each table.
SELECT pr.name AS grantee, p.class_desc, SCHEMA_NAME(p.major_id) AS schema_name,
       p.permission_name, p.state_desc
FROM sys.database_permissions AS p
JOIN sys.database_principals AS pr ON pr.principal_id = p.grantee_principal_id
WHERE pr.name = N'md2_lecture';
-- dbo owns the schema, and through it every table that does not have an owner of its own.
SELECT s.name AS schema_name, USER_NAME(s.principal_id) AS schema_owner,
       t.name AS table_name, USER_NAME(t.principal_id) AS table_owner
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
ORDER BY t.name;
