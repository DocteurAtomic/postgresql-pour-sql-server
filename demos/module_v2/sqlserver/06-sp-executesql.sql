-- ci: skip (T-SQL, plays on SQL Server)
-- Clip V2.6, SQL Server side: sp_executesql with a parameter, and the concatenation it
-- replaces. Read only, in PachaDataFormation (sqlcmd).
SET NOCOUNT ON;
DECLARE @nom varchar(50) = 'x'' or ''x'' = ''x';
DECLARE @sql nvarchar(400) = N'SELECT COUNT(*) AS injected FROM Contact.ProspectUS WHERE Nom = '''
    + @nom + N'''';
EXEC (@sql);
EXEC sp_executesql
    N'SELECT COUNT(*) AS parameter FROM Contact.ProspectUS WHERE Nom = @nom',
    N'@nom varchar(50)',
    @nom = @nom;
GO
