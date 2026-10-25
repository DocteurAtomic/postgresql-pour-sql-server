# Exercice du module 4

Relever les colonnes `char(n)` du portage, mesurer ce qu'elles contiennent, et proposer leur
type cible dans PostgreSQL.

Prérequis : le labo démarré (`./setup/install.sh`), la base `pachadataformation` restaurée.

## Point de départ

    docker compose exec db psql -U postgres -d pachadataformation -f /exercises/module_04/1-inventory.sql

Le script liste les 23 colonnes `char(n)` de la base. Il ne crée rien.

## Les questions

1. Pour chaque colonne, comptez les valeurs non nulles et les valeurs distinctes, et relevez la
   longueur la plus courte et la plus longue, espaces de fin ignorés. Écrivez une seule
   requête, construite à partir de `information_schema.columns` et exécutée par `\gexec`.
2. Quelles colonnes ne contiennent que des valeurs de la longueur déclarée ? Lesquelles
   contiennent des valeurs plus courtes, et lesquelles sont vides ?
3. Une colonne a une longueur minimale de 0. Que contiennent ces valeurs, et que
   deviennent-elles converties en `text` ? Combien y en a-t-il, à côté des `NULL` ?
4. Proposez un type cible pour chaque colonne : `text`, `varchar(n)`, `char(n)` gardé, ou un
   autre type. Justifiez les cas où une contrainte `CHECK` est utile.
5. Sur une copie de `stage.session`, convertissez `statut` en `text` avec une contrainte qui
   n'accepte que les valeurs présentes, et vérifiez ce que devient la valeur stockée.

## Le corrigé

`2-solution.sql` répond aux questions 1, 3 et 5, et supprime la table `outils.m04_exercise`
qu'il crée :

    docker compose exec db psql -U postgres -d pachadataformation -f /exercises/module_04/2-solution.sql
