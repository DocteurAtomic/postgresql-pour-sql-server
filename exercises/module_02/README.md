# Exercice du module 2

Retrouver les processus de l'instance et les fichiers d'une table, avec psql puis depuis le
conteneur du labo.

Prérequis : le labo démarré (`./setup/install.sh`), la base `pachadataformation` restaurée.

## Préparation

    docker compose exec db psql -U postgres -d pachadataformation -f /exercises/module_02/1-start.sql

Le script crée `outils.m02_exercise`, une copie de `inscription.facture`, pour la question 4.

## Les questions

1. Listez les processus de l'instance par type, à partir de `pg_stat_activity`. Retrouvez
   le pid du processus qui sert votre session psql, puis retrouvez ce même processus dans
   la liste du système, avec `docker top pgcourse` (ou `podman top pgcourse`). Quel
   processus n'apparaît pas dans `pg_stat_activity` ?
2. Donnez le chemin, relatif au répertoire de données, du fichier de la table
   `inscription.facture` et de chacun de ses index. Combien de fichiers faut-il pour cette
   table et ses index, en comptant les fichiers `_fsm` et `_vm` ? Vérifiez-le avec `ls -l`
   dans le conteneur.
3. Comparez la taille de la table, celle de ses index et la taille totale. Que dit la
   comparaison sur les quatre index `nix_facture_relance*` ?
4. Relevez l'OID et le `relfilenode` de `outils.m02_exercise`, lancez
   `VACUUM FULL outils.m02_exercise`, puis relevez-les de nouveau. Qu'est-ce qui a changé,
   et pourquoi un script qui cherche le fichier d'une table par son OID se trompe-t-il ?

## Le corrigé

`2-solution.sql` répond aux questions 1 à 4 en SQL et supprime `outils.m02_exercise`.
`2-solution.sh` montre les processus et les fichiers depuis le conteneur
(`DOCKER=podman ./exercises/module_02/2-solution.sh` avec Podman).
