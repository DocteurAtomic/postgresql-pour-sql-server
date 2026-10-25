-- ci: skip (T-SQL, plays on SQL Server)
-- Module V2 exercise, the T-SQL procedure to port (SQL Server 2022, sqlcmd or SSMS).
-- Creates the database MV2PgExercise with copies of four tables of PachaDataFormation,
-- which is only read, then the procedure dbo.Inscrire, then calls it.
-- 9-cleanup.sql drops the database.
SET NOCOUNT ON;
IF DB_ID(N'MV2PgExercise') IS NOT NULL
BEGIN
    ALTER DATABASE MV2PgExercise SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE MV2PgExercise;
END;
CREATE DATABASE MV2PgExercise;
GO
USE MV2PgExercise;
SET NOCOUNT ON;
SELECT ContactId, Nom, Prenom INTO dbo.Contact FROM PachaDataFormation.Contact.Contact;
SELECT SalleFormationId, Places INTO dbo.SalleFormation FROM PachaDataFormation.Reference.SalleFormation;
SELECT SessionId, SalleFormationId, DateDebut INTO dbo.Session FROM PachaDataFormation.Stage.Session;
SELECT InscriptionId, SessionId, ContactId, DateAnnulation, Remise, ListeAttente, DateCreation
INTO dbo.Inscription
FROM PachaDataFormation.Inscription.Inscription;
ALTER TABLE dbo.Contact ADD CONSTRAINT PK_Contact PRIMARY KEY (ContactId);
ALTER TABLE dbo.SalleFormation ADD CONSTRAINT PK_SalleFormation PRIMARY KEY (SalleFormationId);
ALTER TABLE dbo.Session ADD CONSTRAINT PK_Session PRIMARY KEY (SessionId);
ALTER TABLE dbo.Inscription ADD CONSTRAINT PK_Inscription PRIMARY KEY (InscriptionId);
ALTER TABLE dbo.Inscription ADD CONSTRAINT fk_Inscription_Session
    FOREIGN KEY (SessionId) REFERENCES dbo.Session (SessionId);
ALTER TABLE dbo.Inscription ADD CONSTRAINT fk_Inscription_Contact
    FOREIGN KEY (ContactId) REFERENCES dbo.Contact (ContactId);
GO

-- Enrolls a contact in a session. A full session puts the contact on the waiting list.
CREATE OR ALTER PROCEDURE dbo.Inscrire
    @ContactId int,
    @SessionId int,
    @Remise smallint = 0,
    @InscriptionId int OUTPUT,
    @ListeAttente bit OUTPUT
AS BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Contact WHERE ContactId = @ContactId)
        THROW 50001, N'Contact inconnu.', 1;
    IF @Remise NOT BETWEEN 0 AND 100
        THROW 50003, N'La remise doit être comprise entre 0 et 100.', 1;

    BEGIN TRY
        BEGIN TRAN;

        IF EXISTS (SELECT 1 FROM dbo.Inscription
                   WHERE ContactId = @ContactId AND SessionId = @SessionId
                     AND DateAnnulation IS NULL)
            THROW 50002, N'Contact déjà inscrit à cette session.', 1;

        -- The places of the room; a session without a room has no limit.
        DECLARE @Places smallint, @Inscrits int;
        SELECT @Places = sf.Places
        FROM dbo.Session AS s WITH (UPDLOCK, HOLDLOCK)
        LEFT JOIN dbo.SalleFormation AS sf ON sf.SalleFormationId = s.SalleFormationId
        WHERE s.SessionId = @SessionId;

        SELECT @Inscrits = COUNT(*)
        FROM dbo.Inscription
        WHERE SessionId = @SessionId AND DateAnnulation IS NULL AND ListeAttente = 0;

        SET @ListeAttente = CASE WHEN @Inscrits >= @Places THEN 1 ELSE 0 END;

        -- An unknown session: the foreign key fk_Inscription_Session refuses the row.
        INSERT INTO dbo.Inscription (SessionId, ContactId, Remise, ListeAttente, DateCreation)
        VALUES (@SessionId, @ContactId, @Remise, @ListeAttente, SYSDATETIME());
        SET @InscriptionId = SCOPE_IDENTITY();

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO

-- The calls: a session with places left, a full one, a duplicate, an unknown session.
SET NOCOUNT ON;
DECLARE @open int, @full int, @contact int, @id int, @wait bit;
SELECT TOP (1) @open = s.SessionId
FROM dbo.Session AS s
JOIN dbo.SalleFormation AS sf ON sf.SalleFormationId = s.SalleFormationId
WHERE sf.Places > (SELECT COUNT(*) FROM dbo.Inscription AS i
                   WHERE i.SessionId = s.SessionId AND i.DateAnnulation IS NULL AND i.ListeAttente = 0)
ORDER BY s.SessionId;
SELECT TOP (1) @full = s.SessionId
FROM dbo.Session AS s
JOIN dbo.SalleFormation AS sf ON sf.SalleFormationId = s.SalleFormationId
WHERE sf.Places <= (SELECT COUNT(*) FROM dbo.Inscription AS i
                    WHERE i.SessionId = s.SessionId AND i.DateAnnulation IS NULL AND i.ListeAttente = 0)
ORDER BY s.SessionId;
SELECT @contact = MIN(ContactId) FROM dbo.Contact;

EXEC dbo.Inscrire @ContactId = @contact, @SessionId = @open,
    @InscriptionId = @id OUTPUT, @ListeAttente = @wait OUTPUT;
SELECT 'open session' AS test_case, @open AS session_id, @id AS inscription_id, @wait AS waiting_list;
EXEC dbo.Inscrire @ContactId = @contact, @SessionId = @full,
    @InscriptionId = @id OUTPUT, @ListeAttente = @wait OUTPUT;
SELECT 'full session' AS test_case, @full AS session_id, @id AS inscription_id, @wait AS waiting_list;
BEGIN TRY
    EXEC dbo.Inscrire @ContactId = @contact, @SessionId = @open,
        @InscriptionId = @id OUTPUT, @ListeAttente = @wait OUTPUT;
END TRY
BEGIN CATCH
    SELECT 'duplicate' AS test_case, ERROR_NUMBER() AS error_number, ERROR_MESSAGE() AS message;
END CATCH;
BEGIN TRY
    EXEC dbo.Inscrire @ContactId = @contact, @SessionId = -1,
        @InscriptionId = @id OUTPUT, @ListeAttente = @wait OUTPUT;
END TRY
BEGIN CATCH
    SELECT 'unknown session' AS test_case, ERROR_NUMBER() AS error_number, ERROR_MESSAGE() AS message;
END CATCH;
GO
