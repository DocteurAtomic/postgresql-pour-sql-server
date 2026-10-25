select inscriptionid, contactid, dateannulation
from outils.mv4_inscription
where dateannulation >= date '2026-06-01'
