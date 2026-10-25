select i.inscriptionid, c.nom, c.prenom, s.datedebut
from inscription.inscription as i
join contact.contact as c on c.contactid = i.contactid
join stage.session as s on s.sessionid = i.sessionid
where i.inscriptionid between 1000 and 1019
