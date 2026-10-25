-- Clip D3.1: the recovery model, a property of each database. SQL Server 2022, read only.
SET NOCOUNT ON;
SELECT name, recovery_model_desc, log_reuse_wait_desc
FROM sys.databases
WHERE name IN (N'master', N'model', N'msdb', N'PachaDataFormation')
ORDER BY database_id;
