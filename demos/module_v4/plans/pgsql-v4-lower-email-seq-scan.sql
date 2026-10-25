select inscriptionid, sessionid
from outils.mv4_inscription
where lower(email) = lower('L.Joly@Accuquote.example')
