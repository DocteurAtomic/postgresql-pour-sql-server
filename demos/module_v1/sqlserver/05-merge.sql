-- ci: skip (T-SQL, plays on SQL Server)
-- Clip V1.5, SQL Server side: the upsert with MERGE and OUTPUT $action.
-- Recorded on SQL Server 2022 (sqlcmd), after 00-setup.sql; writes only in MV1PgDml.
-- The first batch fails on purpose.
USE MV1PgDml;
SET NOCOUNT ON;
DROP TABLE IF EXISTS dbo.Catalog, dbo.Import;
CREATE TABLE dbo.Catalog (StageId int PRIMARY KEY, Titre varchar(200) NOT NULL,
                          Prix decimal(8, 2) NOT NULL, Active bit NOT NULL DEFAULT 1);
INSERT INTO dbo.Catalog (StageId, Titre, Prix)
SELECT StageId, Titre, 3500 FROM PachaDataFormation.Stage.StageLangue
WHERE StageId BETWEEN 113 AND 120 AND LangueCd = 'FR';
CREATE TABLE dbo.Import (StageId int, Titre varchar(200), Prix decimal(8, 2));
INSERT INTO dbo.Import VALUES (119, 'PostgreSQL 9 Optimisation', 3900),
                              (120, 'PostgreSQL 9 Prise en Main', 2900),
                              (200, 'PostgreSQL 18 pour SQL Server', 3200);
GO
-- A MERGE must end with a semicolon.
MERGE dbo.Catalog AS c
USING dbo.Import AS i ON i.StageId = c.StageId
WHEN MATCHED THEN UPDATE SET Prix = i.Prix
GO
-- HOLDLOCK serializes concurrent upserts on the same key.
MERGE dbo.Catalog WITH (HOLDLOCK) AS c
USING dbo.Import AS i ON i.StageId = c.StageId
WHEN MATCHED AND c.Prix <> i.Prix THEN
    UPDATE SET Prix = i.Prix
WHEN NOT MATCHED THEN
    INSERT (StageId, Titre, Prix) VALUES (i.StageId, i.Titre, i.Prix)
WHEN NOT MATCHED BY SOURCE AND c.Active = 1 THEN
    UPDATE SET Active = 0
OUTPUT $action AS action, inserted.StageId, deleted.Prix AS old_price,
       inserted.Prix AS new_price, inserted.Active;
DROP TABLE dbo.Catalog, dbo.Import;
GO
