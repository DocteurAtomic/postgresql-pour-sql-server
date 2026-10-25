-- ci: skip
-- Module D8 exercise: what Stage.Session holds before you migrate it. SQL Server, sqlcmd,
-- database PachaDataFormation, read only:
--   docker exec -i -e SQLCMDPASSWORD pgd8-exsql /opt/mssql-tools18/bin/sqlcmd -S localhost \
--       -U sa -C -d PachaDataFormation -W -s'|' < exercises/module_d8/2-inventory.sql
SET NOCOUNT ON;
SELECT c.name AS column_name, TYPE_NAME(c.user_type_id) AS data_type, c.max_length, c.precision,
       c.scale, c.is_nullable, c.is_identity, OBJECT_DEFINITION(c.default_object_id) AS default_value
FROM sys.columns AS c
WHERE c.object_id = OBJECT_ID('Stage.Session')
ORDER BY c.column_id;

SELECT COUNT(*) AS sessions, IDENT_CURRENT('Stage.Session') AS ident_current,
       MAX(SessionId) AS max_sessionid
FROM Stage.Session;

SELECT name AS foreign_key, OBJECT_SCHEMA_NAME(referenced_object_id) + '.' + OBJECT_NAME(referenced_object_id) AS referenced_table
FROM sys.foreign_keys
WHERE parent_object_id = OBJECT_ID('Stage.Session');

-- Characters that a file format has to carry: tabs, line feeds, carriage returns, backslashes.
SELECT SUM(CASE WHEN Remarques LIKE '%' + CHAR(9) + '%' THEN 1 ELSE 0 END) AS with_tab,
       SUM(CASE WHEN Remarques LIKE '%' + CHAR(10) + '%' THEN 1 ELSE 0 END) AS with_line_feed,
       SUM(CASE WHEN Remarques LIKE '%' + CHAR(13) + '%' THEN 1 ELSE 0 END) AS with_carriage_return,
       SUM(CASE WHEN CHARINDEX('\', Remarques) > 0 THEN 1 ELSE 0 END) AS with_backslash
FROM Stage.Session;
