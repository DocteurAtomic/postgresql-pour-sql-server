select doc ->> 'inscriptionid'
from outils.mv5_evaluation
where doc @> '{"sessionid": 40}'
