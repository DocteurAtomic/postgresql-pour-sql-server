-- ci: skip
-- Module D8 exercise: the profile of Stage.Session, one line per column:
-- table|column|non-null values|sum or total length|minimum|maximum.
-- SQL Server, sqlcmd -h -1, database PachaDataFormation, read only. The same generator as
-- demos/module_d8/sqlserver/05-profile.sql, for one table. Write its PostgreSQL twin.
SET NOCOUNT ON;
DECLARE @sql nvarchar(max);
SELECT @sql = STRING_AGG(CONVERT(nvarchar(max),
    N'SELECT ''' + LOWER(c.TABLE_SCHEMA + N'.' + c.TABLE_NAME) + N'|' + LOWER(c.COLUMN_NAME) + N'|'' + CONCAT(' +
    CASE
      -- numbers: sum and bounds as decimal(38,4), the same text on both sides
      WHEN c.DATA_TYPE IN (N'int', N'smallint', N'tinyint', N'bigint', N'decimal', N'numeric', N'float', N'real')
        THEN N'COUNT(' + QUOTENAME(c.COLUMN_NAME) + N'), ''|'', CONVERT(decimal(38,4), SUM(CONVERT(decimal(38,4), ' + QUOTENAME(c.COLUMN_NAME) + N'))), ''|'', CONVERT(decimal(38,4), MIN(' + QUOTENAME(c.COLUMN_NAME) + N')), ''|'', CONVERT(decimal(38,4), MAX(' + QUOTENAME(c.COLUMN_NAME) + N'))'
      -- bit: the number of 1, against the number of true
      WHEN c.DATA_TYPE = N'bit'
        THEN N'COUNT(' + QUOTENAME(c.COLUMN_NAME) + N'), ''|'', SUM(CONVERT(int, ' + QUOTENAME(c.COLUMN_NAME) + N')), ''|'', MIN(CONVERT(int, ' + QUOTENAME(c.COLUMN_NAME) + N')), ''|'', MAX(CONVERT(int, ' + QUOTENAME(c.COLUMN_NAME) + N'))'
      WHEN c.DATA_TYPE = N'date'
        THEN N'COUNT(' + QUOTENAME(c.COLUMN_NAME) + N'), ''|'', '''', ''|'', CONVERT(char(10), MIN(' + QUOTENAME(c.COLUMN_NAME) + N'), 23), ''|'', CONVERT(char(10), MAX(' + QUOTENAME(c.COLUMN_NAME) + N'), 23)'
      WHEN c.DATA_TYPE IN (N'datetime', N'smalldatetime', N'datetime2')
        THEN N'COUNT(' + QUOTENAME(c.COLUMN_NAME) + N'), ''|'', '''', ''|'', CONVERT(char(19), MIN(' + QUOTENAME(c.COLUMN_NAME) + N'), 120), ''|'', CONVERT(char(19), MAX(' + QUOTENAME(c.COLUMN_NAME) + N'), 120)'
      -- char(n): length and bounds without the trailing blanks, as PostgreSQL gives them
      WHEN c.DATA_TYPE IN (N'char', N'nchar')
        THEN N'COUNT(' + QUOTENAME(c.COLUMN_NAME) + N'), ''|'', SUM(CONVERT(bigint, LEN(' + QUOTENAME(c.COLUMN_NAME) + N'))), ''|'', RTRIM(MIN(' + QUOTENAME(c.COLUMN_NAME) + N' COLLATE Latin1_General_BIN2)), ''|'', RTRIM(MAX(' + QUOTENAME(c.COLUMN_NAME) + N' COLLATE Latin1_General_BIN2))'
      -- varchar: length with the trailing blanks, which LEN() alone would drop
      WHEN c.DATA_TYPE IN (N'varchar', N'nvarchar')
        THEN N'COUNT(' + QUOTENAME(c.COLUMN_NAME) + N'), ''|'', SUM(CONVERT(bigint, LEN(' + QUOTENAME(c.COLUMN_NAME) + N' + ''x'') - 1)), ''|'', '''', ''|'', '''''
      -- geography: the length of its WKT text, which is what PostgreSQL received
      WHEN c.DATA_TYPE = N'geography'
        THEN N'COUNT(' + QUOTENAME(c.COLUMN_NAME) + N'), ''|'', SUM(CONVERT(bigint, LEN(' + QUOTENAME(c.COLUMN_NAME) + N'.STAsText()))), ''|'', '''', ''|'', '''''
    END +
    N') FROM ' + QUOTENAME(c.TABLE_SCHEMA) + N'.' + QUOTENAME(c.TABLE_NAME)),
    NCHAR(10) + N'UNION ALL ')
FROM INFORMATION_SCHEMA.COLUMNS AS c
WHERE c.TABLE_SCHEMA = N'Stage' AND c.TABLE_NAME = N'Session';
EXEC sys.sp_executesql @sql;
