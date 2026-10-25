# Exercice du module 5

Lire le plan d'une requête à trois tables, trouver où l'estimation s'écarte du réel, et
l'expliquer par les statistiques.

Prérequis : le labo démarré (`./setup/install.sh`), la base `pachadataformation` restaurée.
L'exercice ne crée rien.

## La requête

`1-query.sql` compte les inscriptions par stage, en joignant `inscription.inscription`,
`stage.session` et `stage.stage` :

    docker compose exec db psql -U postgres -d pachadataformation -f /exercises/module_05/1-query.sql

## Les questions

1. Affichez le plan estimé de la requête, puis son plan réel avec `EXPLAIN ANALYZE`. Quel
   nœud coûte le plus en propre, c'est-à-dire son coût total moins celui de ses enfants ?
   Lequel lit le plus de pages ?
2. À quel nœud l'estimation du nombre de lignes s'écarte-t-elle le plus du réel, et de
   combien ? L'écart change-t-il les nœuds choisis ?
3. Lisez `n_distinct` de la colonne `sessionid` dans `pg_stats`, et comptez les sessions de
   `stage.session`. Retrouvez l'estimation de la jointure. Que montrent les inscriptions dont
   la session n'existe pas ?

## Le corrigé

    docker compose exec db psql -U postgres -d pachadataformation -f /exercises/module_05/2-solution.sql

Le script affiche les deux plans et fait les calculs de la question 3. Il ne modifie rien.
