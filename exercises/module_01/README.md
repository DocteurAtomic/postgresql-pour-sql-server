# Exercice du module 1

Objectif : monter le labo sur votre poste, puis dresser l'inventaire de la base
`pachadataformation` avec psql, comme vous le feriez avec l'explorateur d'objets de SSMS
en arrivant sur une base SQL Server inconnue.

## Le labo

Clonez le dépôt et lancez le script d'installation :

    git clone https://github.com/DocteurAtomic/postgresql-pour-sql-server.git
    cd postgresql-pour-sql-server
    ./setup/install.sh

Avec Podman : `COMPOSE="podman compose" ./setup/install.sh`. Le script doit finir sur la
ligne `34 tables restored`. Ouvrez ensuite psql dans le conteneur :

    docker compose exec db psql -U postgres -d pachadataformation

Jouez `\i /demos/module_01/00-setup.sql` : il vérifie que le serveur est un PostgreSQL 18
et compte les tables de la base.

## L'inventaire

Le fichier de départ, `1-inventory.sql`, pose six questions. Écrivez sous chacune une
requête ou une méta-commande de psql :

1. La version du serveur, la taille de la base, et les bases de l'instance (hors bases
   modèles).
2. Pour chaque schéma, le nombre de tables et leur taille totale, index compris, du plus
   gros au plus petit.
3. Les cinq tables les plus grosses, avec leur nombre de lignes estimé
   (`pg_class.reltuples`), puis le nombre exact de lignes de la plus grosse.
4. Les tables qui n'ont pas de clé primaire.
5. Avec `\gexec`, le nombre exact de lignes de chaque table du schéma `inscription`.
6. Les rôles qui peuvent se connecter.

Les vues du catalogue utiles sont `pg_database`, `pg_namespace`, `pg_class`, `pg_tables`,
`pg_constraint` et `pg_roles`, et les fonctions `pg_database_size` et
`pg_total_relation_size`.

## La vérification

- Une ligne de la question 3 a-t-elle un nombre estimé différent du nombre exact ? Le script
  d'installation a lancé `vacuumdb --analyze`, qui a calculé ces estimations.
- À la question 4, une table s'affiche sans le nom de son schéma. Pourquoi ?
- Comparez la question 5 avec ce que vous écririez dans SQL Server pour compter les lignes
  de toutes les tables d'un schéma.

## Le corrigé

`2-solution.sql` répond aux six questions. Il ne fait que lire la base. Sur le
labo, trois tables n'ont pas de clé primaire, `contact.prospectus` est la plus grosse
(300 000 lignes), et deux tables du schéma `inscription`, `adressesurinscription` et
`evaluation`, sont vides.
