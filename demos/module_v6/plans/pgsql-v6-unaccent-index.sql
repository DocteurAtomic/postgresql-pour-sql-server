select contactid, prenom from outils.mv6_contact
where lower(outils.mv6_unaccent(prenom)) = 'helene'
