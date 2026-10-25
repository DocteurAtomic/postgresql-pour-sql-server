select stageid, titre from outils.mv6_programme
where to_tsvector('french', programme) @@ plainto_tsquery('french', 'sauvegarde')
