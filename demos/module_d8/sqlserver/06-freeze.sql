-- Clip D8.6: freezing the writes before the last copy. SQL Server 2022 (sql2022), sqlcmd.
-- Played on a database of the module, MD8PgCutover, created and dropped here:
-- PachaDataFormation is not touched.
SET NOCOUNT ON;
IF DB_ID(N'MD8PgCutover') IS NOT NULL DROP DATABASE MD8PgCutover;
CREATE DATABASE MD8PgCutover;
GO
USE MD8PgCutover;
CREATE TABLE dbo.Inscription (InscriptionId int IDENTITY PRIMARY KEY, SessionId int NOT NULL);
INSERT dbo.Inscription (SessionId) VALUES (1);
GO
USE master;
-- The sessions still connected are rolled back and disconnected.
ALTER DATABASE MD8PgCutover SET READ_ONLY WITH ROLLBACK IMMEDIATE;
SELECT name, is_read_only FROM sys.databases WHERE name = N'MD8PgCutover';
GO
USE MD8PgCutover;
INSERT dbo.Inscription (SessionId) VALUES (2);
GO
-- The way back, if the cutover is abandoned.
USE master;
ALTER DATABASE MD8PgCutover SET READ_WRITE WITH ROLLBACK IMMEDIATE;
SELECT name, is_read_only FROM sys.databases WHERE name = N'MD8PgCutover';
DROP DATABASE MD8PgCutover;
GO
