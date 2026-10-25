-- ci: skip (T-SQL, plays on SQL Server)
-- Clip V2.5, SQL Server side, second part: the trigger reads one row of inserted.
-- Run after 05a-trigger.sql, connected to MV2PgDemo (sqlcmd -d MV2PgDemo), where it writes.
-- No USE here: after a USE batch, sqlcmd answers the batches that follow the trigger's
-- ROLLBACK with "Invalid cursor state" instead of their results.
-- The invalid email on contact 1: rejected.
UPDATE dbo.Contact
SET Email = CASE ContactId WHEN 1 THEN 'not-an-email' ELSE 'second@contact.example' END
WHERE ContactId IN (1, 2);
GO
SET NOCOUNT ON;
SELECT COUNT(*) AS invalid_emails FROM dbo.Contact WHERE Email = 'not-an-email';
GO
-- The invalid email on contact 2: accepted, the trigger read contact 1 only.
UPDATE dbo.Contact
SET Email = CASE ContactId WHEN 2 THEN 'not-an-email' ELSE 'first@contact.example' END
WHERE ContactId IN (1, 2);
SELECT ContactId, Email FROM dbo.Contact WHERE ContactId IN (1, 2) ORDER BY ContactId;
GO
