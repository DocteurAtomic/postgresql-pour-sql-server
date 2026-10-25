select inscriptionid, sessionid
from outils.mv4_inscription
where options @> '{"amenagement": "pmr"}'
