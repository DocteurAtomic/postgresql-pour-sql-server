-- Clip D7.1: version, update level and compatibility levels of the comparison instance.
-- SQL Server 2022 (sql2022), sqlcmd, read only.
SET NOCOUNT ON;
SELECT SERVERPROPERTY('ProductMajorVersion') AS major_version,
       SERVERPROPERTY('ProductVersion') AS product_version,
       SERVERPROPERTY('ProductLevel') AS product_level,
       SERVERPROPERTY('ProductUpdateLevel') AS update_level;

SELECT name, compatibility_level
FROM sys.databases
ORDER BY database_id;
