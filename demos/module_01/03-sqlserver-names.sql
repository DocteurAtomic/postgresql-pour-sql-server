-- ci: skip (T-SQL, plays on SQL Server)
-- Clip 1.3: the same question asked to SQL Server, in sqlcmd or SSMS, on the database
-- PachaDataFormation. Read only.
SELECT DB_NAME() AS database_name,
       SCHEMA_NAME() AS default_schema,
       SUSER_SNAME() AS login_name,
       USER_NAME() AS user_name;
GO
