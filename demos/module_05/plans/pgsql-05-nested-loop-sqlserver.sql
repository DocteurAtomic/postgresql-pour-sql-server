SELECT i.InscriptionId, c.Nom, c.Prenom, s.DateDebut
FROM Inscription.Inscription AS i
JOIN Contact.Contact AS c ON c.ContactId = i.ContactId
JOIN Stage.Session AS s ON s.SessionId = i.SessionId
WHERE i.InscriptionId BETWEEN 1000 AND 1019;
