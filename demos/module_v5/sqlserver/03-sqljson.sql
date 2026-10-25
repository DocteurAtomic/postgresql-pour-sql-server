-- ci: skip (T-SQL, plays on SQL Server)
-- Clip V5.3, SQL Server 2022 side: the same functions on a document held in a variable.
-- Read only (sqlcmd, database PachaDataFormation).
SET NOCOUNT ON;
DECLARE @doc nvarchar(max) = N'{"date": "2011-10-02", "notes": {"support": 5, "animation": 2, "exercices": 4},
  "themes": ["exercices"], "sessionid": 40, "recommande": true, "inscriptionid": 15478}';
SELECT JSON_VALUE(@doc, '$.notes.animation') AS animation,
       JSON_QUERY(@doc, '$.themes') AS themes,
       JSON_VALUE(@doc, '$.notes') AS notes_as_value,
       JSON_PATH_EXISTS(@doc, '$.commentaire') AS has_comment;
-- The nvarchar returned by JSON_VALUE is converted to int implicitly.
SELECT CASE WHEN JSON_VALUE(@doc, '$.sessionid') = 40 THEN 'match' ELSE 'no match' END AS implicit_conversion;
-- OPENJSON ... WITH, and a second OPENJSON for the array.
SELECT j.inscriptionid, j.animation, j.recommande, t.value AS theme
FROM OPENJSON(@doc)
     WITH (inscriptionid int '$.inscriptionid',
           animation int '$.notes.animation',
           recommande bit '$.recommande',
           themes nvarchar(max) '$.themes' AS JSON) AS j
OUTER APPLY OPENJSON(j.themes) AS t;
-- JSON_ARRAY drops NULL, JSON_OBJECT keeps it.
SELECT JSON_ARRAY(1, 2, NULL) AS json_array, JSON_OBJECT('salle': NULL) AS json_object;
-- FOR JSON PATH.
SELECT SessionId AS sessionid, DateDebut AS debut
FROM Stage.Session
WHERE StageId = 12 AND SessionId <= 300
ORDER BY SessionId
FOR JSON PATH;
GO
-- strict: a missing key is an error.
SELECT JSON_VALUE(N'{"a": 1}', 'strict $.commentaire') AS strict_missing;
GO
-- JSON_ARRAYAGG does not exist before SQL Server 2025.
SELECT JSON_ARRAYAGG(SessionId) AS sessions FROM Stage.Session WHERE StageId = 12;
GO
