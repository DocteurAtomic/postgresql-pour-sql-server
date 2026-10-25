select id from outils.mv6_vecteur
where categorie = 7
order by embedding <-> (select embedding from outils.mv6_vecteur where id = 42)
limit 10
