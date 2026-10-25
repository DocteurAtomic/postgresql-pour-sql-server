select count(*), avg(remise)
from outils.mv4_inscription
where datecreation >= timestamp '2026-03-01' and datecreation < timestamp '2026-04-01'
