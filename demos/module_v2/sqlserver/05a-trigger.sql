-- ci: skip (T-SQL, plays on SQL Server)
-- Clip V2.5, SQL Server side, first part: Contact.atr_Contact_CheckEmail of
-- PachaDataFormation, created on the copy dbo.Contact of MV2PgDemo (sqlcmd).
-- Then run 05b-trigger-updates.sql in a new connection (see its header).
USE MV2PgDemo;
GO
CREATE OR ALTER TRIGGER dbo.atr_Contact_CheckEmail
ON dbo.Contact
AFTER UPDATE
AS BEGIN
	IF @@ROWCOUNT = 0 RETURN;
	SET NOCOUNT ON;

	DECLARE @email varchar(150);
	SELECT @email = email FROM inserted;

	IF @email NOT LIKE '%_@_%._%' BEGIN
		RAISERROR('email invalide', 16, 10);
		ROLLBACK;
	END;

END;
GO
