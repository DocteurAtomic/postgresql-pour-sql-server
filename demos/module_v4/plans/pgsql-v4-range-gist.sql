select inscriptionid, sessionid
from outils.mv4_inscription
where periode @> date '2026-03-12'
