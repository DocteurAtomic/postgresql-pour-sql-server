-- ci: skip (T-SQL, plays on SQL Server)
-- Module V5 exercise, SQL Server side: the same document for one stage with FOR JSON PATH,
-- the way it is usually built in T-SQL. Read only (sqlcmd, database PachaDataFormation).
-- The data of PachaDataFormation is not the data of the port: compare the shape, not the
-- values.
SET NOCOUNT ON;
SELECT st.StageId AS stageid,
       sl.Titre AS titre,
       st.Duree AS duree,
       (SELECT s.SessionId AS sessionid, s.DateDebut AS debut, s.SalleFormationId AS salle,
               JSON_QUERY((SELECT N'[' + STRING_AGG(CAST(i.ContactId AS nvarchar(max)), N',')
                                  WITHIN GROUP (ORDER BY i.ContactId) + N']'
                           FROM Inscription.Inscription AS i
                           WHERE i.SessionId = s.SessionId)) AS inscrits
        FROM Stage.Session AS s
        WHERE s.StageId = st.StageId AND s.DateDebut < '2011-03-01'
        ORDER BY s.DateDebut
        FOR JSON PATH) AS sessions
FROM Stage.Stage AS st
JOIN Stage.StageLangue AS sl ON sl.StageId = st.StageId AND sl.LangueCd = 'FR'
WHERE st.StageId = 12
FOR JSON PATH, WITHOUT_ARRAY_WRAPPER;
GO
