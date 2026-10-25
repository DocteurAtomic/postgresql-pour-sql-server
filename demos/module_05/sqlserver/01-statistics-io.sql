-- Clip 5.1, SQL Server side. sql2022, database PachaDataFormation, sqlcmd. Reads only.
-- The same twenty enrollments: the estimated plan as text, then the query with
-- SET STATISTICS IO, the reads per table that PostgreSQL gives per node as Buffers.
SET SHOWPLAN_TEXT ON;
GO
SELECT i.InscriptionId, c.Nom, c.Prenom, s.DateDebut
FROM Inscription.Inscription AS i
JOIN Contact.Contact AS c ON c.ContactId = i.ContactId
JOIN Stage.Session AS s ON s.SessionId = i.SessionId
WHERE i.InscriptionId BETWEEN 1000 AND 1019;
GO
SET SHOWPLAN_TEXT OFF;
GO
SET STATISTICS IO ON;
SET NOCOUNT ON;
SELECT i.InscriptionId, c.Nom, c.Prenom, s.DateDebut
FROM Inscription.Inscription AS i
JOIN Contact.Contact AS c ON c.ContactId = i.ContactId
JOIN Stage.Session AS s ON s.SessionId = i.SessionId
WHERE i.InscriptionId BETWEEN 1000 AND 1019;
SET STATISTICS IO OFF;
GO
