# Exercice du module D8

Migrer une table de PachaDataFormation, `Stage.Session`, de SQL Server vers PostgreSQL avec
`bcp` et `COPY`, puis prouver que rien n'a été perdu.

Prérequis : Docker ou Podman, environ 2 Go de mémoire libre pour SQL Server, et le réseau au
premier lancement (l'image `mcr.microsoft.com/mssql/server:2022-latest` et la sauvegarde de
la base, 91 Mo). L'exercice ne touche pas au labo du cours : il se joue dans ses conteneurs,
`pgd8-expg` (PostgreSQL 18, base `pachadata` vide) et `pgd8-exsql` (SQL Server 2022, édition
Developer), sur le réseau `pgd8-exnet`.

## Préparation

Choisissez un mot de passe pour le compte `sa` du conteneur SQL Server (huit caractères au
moins, de trois sortes), et gardez-le dans une variable d'environnement : les scripts le lisent
là, et ne l'écrivent nulle part.

    read -rs MSSQL_SA_PASSWORD && export MSSQL_SA_PASSWORD
    ./exercises/module_d8/1-start.sh

(`DOCKER=podman ./exercises/module_d8/1-start.sh` avec Podman.) Le script télécharge la
sauvegarde publique de PachaDataFormation (version de 2019) dans `~/.cache/pgd8`, vérifie sa
somme SHA-256, démarre `pgd8-exsql`, y restaure la base, et démarre `pgd8-expg`. Si vous avez
déjà un conteneur SQL Server avec PachaDataFormation, passez son nom :
`MSSQL_CONTAINER=<nom> ./exercises/module_d8/1-start.sh` ; les chiffres du corrigé sont ceux
de la sauvegarde de 2019.

Pour se connecter :

    export SQLCMDPASSWORD="$MSSQL_SA_PASSWORD"
    docker exec -it -e SQLCMDPASSWORD pgd8-exsql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -C -d PachaDataFormation
    docker exec -it pgd8-expg psql -U postgres -d pachadata

`bcp` est dans le même dossier que `sqlcmd`. Sans `-P`, il lit le mot de passe sur son entrée
standard, ce qui le garde hors de la ligne de commande.

## Les questions

1. Jouez `2-inventory.sql` sur SQL Server. Quels types PostgreSQL choisissez-vous pour
   chaque colonne ? Quelle colonne est une identité, et où en est-elle ?
2. Créez `stage.session` dans `pgd8-expg`. Que faites-vous des trois clés étrangères ?
3. Exportez la table par `bcp ... queryout ... -c -C 65001 -t "\t"`, et chargez le fichier par
   `COPY ... (format csv, delimiter E'\t')`. Que répond `COPY`, et pourquoi ? Corrigez
   l'export.
4. Jouez `3-profile-mssql.sql` sur SQL Server (`sqlcmd -h -1`). Écrivez la requête qui calcule
   le même profil dans PostgreSQL, de la même façon, et comparez les deux sorties ligne à
   ligne.
5. Insérez une session sans `sessionid`, puis cinquante. Que se passe-t-il, et à quelle
   valeur ? Corrigez, et comparez avec `IDENT_CURRENT` côté SQL Server.

## Le corrigé

`4-solution.sh` joue les cinq questions avec `4-target.sql` et `4-profile-pg.sql`, puis
supprime les conteneurs et le réseau (`KEEP=1 ./exercises/module_d8/4-solution.sh` pour les
garder). La sauvegarde reste dans `~/.cache/pgd8` ; supprimez-la quand vous n'en avez plus
besoin. Les fonctions `mssql`, `bcp_out` et `start_pg` viennent de `demos/module_d8/lib.sh`.

Les fichiers `.sql` de ce dossier sont marqués `ci: skip` : ils demandent les conteneurs de
l'exercice. Ne lancez rien de ce dossier sur le labo.
