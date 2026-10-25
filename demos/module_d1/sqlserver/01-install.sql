-- Clip D1.1, SQL Server side: what setup decided, and what stays per database.
-- Read only, on any SQL Server instance (recorded on SQL Server 2022, sqlcmd).
SET NOCOUNT ON;
SELECT SERVERPROPERTY('ProductVersion') AS product_version,
       SERVERPROPERTY('Collation') AS server_collation,
       SERVERPROPERTY('InstanceDefaultDataPath') AS default_data_path;

-- Page verification is an option of each database, changed online.
SELECT name, collation_name, page_verify_option_desc
FROM sys.databases
WHERE name IN (N'master', N'model', N'PachaDataFormation')
ORDER BY name;
