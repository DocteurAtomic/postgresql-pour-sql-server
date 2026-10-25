# Exercice du module D7

Passer une instance PostgreSQL de 17 à 18 avec `pg_upgrade --link`, dans un conteneur qui
contient les binaires des deux versions, puis faire ce que `pg_upgrade` demande après.

Prérequis : Docker ou Podman, le dump téléchargé par `./setup/install.sh`, et les images
`postgres:17` et `postgres:18`, que Docker tire au premier usage. L'exercice ne touche pas au
labo du cours : il se joue dans ses conteneurs, `pgd7-exercise` et `pgd7-exercise-18`, sur le
volume `pgd7-exercise`.

## Préparation

    ./exercises/module_d7/1-start.sh

(`DOCKER=podman ./exercises/module_d7/1-start.sh` avec Podman.) Le script démarre
`pgd7-exercise` avec l'image `postgres:17`, le répertoire de données dans
`/var/lib/postgresql/17/docker` du volume, y restaure `pachadataformation`, crée l'extension
`pg_stat_statements` et une statistique étendue sur `inscription.facture`, puis lance deux
requêtes. Pour se connecter :

    docker exec -it pgd7-exercise psql -U postgres -d pachadataformation

`2-check.sql` lit l'instance sans la modifier : version, sommes de contrôle, nombre de lignes
de `pg_stats`, statistiques étendues, tables analysées, version de `pg_stat_statements`, et
l'estimation d'une requête sur deux colonnes liées.

    docker exec -i pgd7-exercise psql -U postgres -d pachadataformation < exercises/module_d7/2-check.sql

## Les questions

1. Jouez `2-check.sql` sur la 17 et gardez le résultat.
2. Arrêtez la 17, puis démarrez sur le même volume un conteneur de l'image `postgres:18` qui
   ne lance pas de serveur (`--entrypoint sleep ... infinity`). Copiez-y les binaires de la 17
   depuis l'image `postgres:17` (`/usr/lib/postgresql/17` et `/usr/share/postgresql/17`).
   Pourquoi est-ce possible entre ces deux images ?
3. Créez la 18 dans `/var/lib/postgresql/18/docker` avec `initdb`, puis lancez
   `pg_upgrade --check --link` en utilisateur `postgres`. Que répond-il, et comment le
   corriger ?
4. Lancez `pg_upgrade --link`. Que vous demande-t-il de faire à la fin, et quels fichiers
   laisse-t-il dans le répertoire courant ?
5. Démarrez la 18 avec `pg_ctl` et rejouez `2-check.sql`. Qu'est-ce qui a été conservé, et
   qu'est-ce qui manque ?
6. Faites ce que `pg_upgrade` a demandé, puis rejouez `2-check.sql`.
7. Pourriez-vous redémarrer la 17 maintenant ?

## Le corrigé

`2-solution.sh` joue les questions 1 à 7, puis supprime les conteneurs et le volume
(`KEEP=1 ./exercises/module_d7/2-solution.sh` pour les garder). La copie des binaires et le
démarrage des deux instances passent par les fonctions `start_old` et `start_new` de
`demos/module_d7/lib.sh`.

`2-check.sql` est marqué `ci: skip`, comme tout ce qui demande les conteneurs de l'exercice.
Ne lancez rien de ce dossier sur le labo.
