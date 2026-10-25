-- ci: skip (T-SQL, plays on SQL Server)
-- Clip V3.1, SQL Server side, database MV3PgTx: nested BEGIN TRAN and @@TRANCOUNT,
-- DDL rolled back, CREATE DATABASE refused in a transaction.
SET NOCOUNT ON;
USE MV3PgTx;
-- 1. BEGIN TRAN twice: @@TRANCOUNT counts them, the inner COMMIT only decrements it.
BEGIN TRAN;
INSERT INTO dbo.Inscription (InscriptionId, SessionId) VALUES (900001, 41);
BEGIN TRAN;
INSERT INTO dbo.Inscription (InscriptionId, SessionId) VALUES (900002, 41);
SELECT @@TRANCOUNT AS trancount_before_commit,
       (SELECT COUNT(*) FROM dbo.Inscription WHERE InscriptionId >= 900000) AS new_rows;
COMMIT;
SELECT @@TRANCOUNT AS trancount_after_commit;
ROLLBACK;                                 -- rolls back both rows
SELECT COUNT(*) AS kept_rows FROM dbo.Inscription WHERE InscriptionId >= 900000;
GO
-- 2. DDL in a transaction, rolled back as in PostgreSQL.
BEGIN TRAN;
CREATE TABLE dbo.Draft (Id int PRIMARY KEY, Label varchar(20));
INSERT INTO dbo.Draft SELECT value, CONCAT('draft ', value) FROM GENERATE_SERIES(1, 1000);
CREATE INDEX IX_Draft_Label ON dbo.Draft (Label);
SELECT COUNT(*) AS rows_in_draft FROM dbo.Draft;
ROLLBACK;
SELECT OBJECT_ID(N'dbo.Draft') AS draft_after_rollback;
GO
-- 3. What refuses to run in a transaction.
BEGIN TRAN;
CREATE DATABASE MV3PgRefused;
GO
IF @@TRANCOUNT > 0 ROLLBACK;
SELECT DB_ID(N'MV3PgRefused') AS refused_database;
GO
