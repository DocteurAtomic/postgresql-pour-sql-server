-- ci: skip (T-SQL, plays on SQL Server)
-- Clip V1.4, SQL Server side: UPDATE ... FROM, DELETE ... FROM and OUTPUT.
-- Recorded on SQL Server 2022 (sqlcmd), after 00-setup.sql; writes only in MV1PgDml.
-- Its data are not those of the port: compare the behaviors, not the rows.
USE MV1PgDml;
SET NOCOUNT ON;
-- The target named by its table, the alias in FROM: SQL Server binds both to one table.
BEGIN TRAN;
UPDATE dbo.Session SET Prix = s.Prix * 1.10
FROM dbo.Session s
JOIN PachaDataFormation.Stage.StageLangue sl ON sl.StageId = s.StageId AND sl.LangueCd = s.LangueCd
WHERE sl.Titre = 'PostgreSQL 9 Optimisation';
SELECT @@ROWCOUNT AS updated_rows;
ROLLBACK;

-- OUTPUT deleted and inserted: the values before and after.
UPDATE s SET Prix = s.Prix * 1.10
OUTPUT inserted.SessionId, deleted.Prix AS old_price, inserted.Prix AS new_price
FROM dbo.Session s
JOIN PachaDataFormation.Stage.StageLangue sl ON sl.StageId = s.StageId AND sl.LangueCd = s.LangueCd
WHERE sl.Titre = 'PostgreSQL 9 Optimisation' AND s.DateDebut >= '2017-06-01';

-- DELETE with a join: the alias after DELETE, a second FROM. Course 24 has one session
-- here, planned before its cancellation (the port has eleven after it).
DELETE s
OUTPUT deleted.SessionId, deleted.DateDebut, st.DateAnnulation
FROM dbo.Session s
JOIN PachaDataFormation.Stage.Stage st ON st.StageId = s.StageId
WHERE st.StageId = 24;

-- OUTPUT inserted gives the identity value.
INSERT INTO dbo.Session (StageId, LangueCd, DateDebut, Prix)
OUTPUT inserted.SessionId
VALUES (119, 'FR', '2026-11-16', 3900);
GO
