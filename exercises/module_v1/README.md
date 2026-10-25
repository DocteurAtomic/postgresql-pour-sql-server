# Exercice du module V1

Réécrire pour PostgreSQL cinq requêtes T-SQL de PachaDataFormation, et repérer celles qui
changeraient de résultat traduites mot à mot.

Prérequis : le labo démarré (`./setup/install.sh`), la base `pachadataformation` restaurée.

## Point de départ

`1-tsql-queries.sql` contient les cinq requêtes, écrites pour la base `PachaDataFormation` de
SQL Server. Ouvrez-le dans un éditeur : il ne se joue pas dans psql. Si vous avez SQL Server,
vous pouvez le jouer sur `PachaDataFormation` ; la quatrième requête s'y exécute dans une
transaction annulée et ne modifie rien.

Les noms de la base sont en casse mixte dans SQL Server (`Stage.Session.DateDebut`) et en
minuscules dans le portage (`stage.session.datedebut`).

## Les questions

1. Les cinq sessions les plus chères de 2020, égalités comprises, avec leur date de fin et leur
   note (0 quand il n'y en a pas). Traduisez `TOP (5) WITH TIES`, `DATEADD` et `ISNULL`.
   Comparez votre résultat avec la traduction la plus directe : que voyez-vous en tête ?
2. Pour chaque lieu de formation, la dernière session tenue dans l'une de ses salles, et les
   lieux sans session. Traduisez `OUTER APPLY`.
3. Pour les stages PostgreSQL 9 : le nombre de sessions en 2019, en 2020, et le prix médian.
   Traduisez les `SUM(CASE ...)` et `PERCENTILE_CONT ... OVER`, sans `DISTINCT`.
4. Augmentez de 5 % le prix des sessions de 2012 tenues au Centre Pacha Genève, et listez
   l'ancien et le nouveau prix. Travaillez sur une copie de `stage.session` dans le schéma
   `outils`. Combien de lignes modifierait la traduction qui garde la table cible dans le
   `FROM` ?
5. Le nombre de sessions par mois de 2012, mois vides compris. Écrivez-le sans récursion.

Deux de ces requêtes, traduites mot à mot, s'exécutent sans erreur et rendent un autre résultat
que dans SQL Server. Lesquelles, et pourquoi ?

## Le corrigé

`2-solution.sql` répond aux cinq questions, et supprime la table `outils.mv1_exercise` qu'il
crée pour la quatrième :

    docker compose exec db psql -U postgres -d pachadataformation -f /exercises/module_v1/2-solution.sql
