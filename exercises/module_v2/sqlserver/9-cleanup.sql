-- ci: skip (T-SQL, plays on SQL Server)
-- Module V2 exercise, SQL Server side, cleanup: drops the database MV2PgExercise.
IF DB_ID(N'MV2PgExercise') IS NOT NULL
BEGIN
    ALTER DATABASE MV2PgExercise SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE MV2PgExercise;
END;
SELECT COUNT(*) AS mv2_exercise_databases FROM sys.databases WHERE name = N'MV2PgExercise';
GO
