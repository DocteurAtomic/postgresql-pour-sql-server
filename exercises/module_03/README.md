# Exercice du module 3

Provoquer un échec de sérialisation entre deux sessions, puis mesurer les tuples morts
qu'une mise à jour laisse dans une table.

Prérequis : le labo démarré (`./setup/install.sh`), la base `pachadataformation` restaurée.

## Préparation

    docker compose exec db psql -U postgres -d pachadataformation -f /exercises/module_03/1-start.sql

Le script crée `outils.m03_exercise`, une copie de `inscription.inscription` (30 436 lignes)
dont l'autovacuum est désactivé pour la mesure de la question 2, et l'extension
`pgstattuple`.

## Les questions

1. Ouvrez deux sessions psql sur la base. Dans chacune, ouvrez une transaction en
   repeatable read et lisez la remise de l'inscription 3. Dans la session A, ajoutez 5 à
   cette remise, sans valider. Dans la session B, faites la même modification. Que fait B
   pendant que A n'a pas validé ? Que se passe-t-il quand A valide ? Quel est le code
   SQLSTATE de l'erreur, et que doit faire l'application qui la reçoit ? Rejouez la scène
   en read committed : qu'est-ce qui change ?
2. Mesurez la table avec `pgstattuple` (taille, tuples vivants, tuples morts, espace libre).
   Inversez la colonne `present` d'une inscription sur trois, et mesurez de nouveau.
   Comparez avec `n_dead_tup` de `pg_stat_user_tables`. Lancez `VACUUM` sur la table et
   mesurez une dernière fois : pourquoi la taille ne baisse-t-elle pas ?

## Le corrigé

`2-session-a.sql` et `2-session-b.sql` jouent la question 1, la session B une seconde après
la session A. Depuis la racine du dépôt :

    ./demos/module_03/scene.sh exercises/module_03/2-session-a.sql exercises/module_03/2-session-b.sql

(`DOCKER=podman` devant la commande avec Podman.) `3-solution.sql` répond à la question 2,
puis supprime `outils.m03_exercise` et l'extension `pgstattuple`. Jouez-le en dernier.
