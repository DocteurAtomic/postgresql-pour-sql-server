select v.nomville, a.adresse1
from reference.ville as v
join contact.adresse as a on a.villeid = v.villeid
where v.codepostal = '51300' and v.coderegion = 21
