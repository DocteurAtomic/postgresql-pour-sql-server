select c.nom, c.prenom, t.nb_inscriptions
from contact.contact as c
cross join lateral outils.mv2_inscriptions_tab_sql(c.contactid) as t
where c.nom = 'Dupont'
