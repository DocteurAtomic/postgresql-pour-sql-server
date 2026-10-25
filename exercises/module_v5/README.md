# Exercice du module V5

Construire un document jsonb par stage, avec ses sessions et leurs inscrits, l'interroger, et le
vérifier contre les tables dont il vient.

Prérequis : le labo démarré (`./setup/install.sh`), la base `pachadataformation` restaurée. Pour
comparer avec SQL Server, un SQL Server avec la base `PachaDataFormation` ; sans lui, lisez le
script et le résultat ci-dessous.

## Point de départ

`1-start.sql` crée la table vide `outils.mv5_stage_doc (stageid, doc jsonb)` et montre, à plat,
les lignes d'où vient le document du stage 12. Le document visé :

    {"stageid": 12, "titre": "Firebird 2.5 Développement", "duree": 5,
     "sessions": [{"sessionid": 259, "debut": "2011-02-01", "salle": 29,
                   "inscrits": [433, 729, ...]}, ...]}

`sqlserver/1-for-json.sql` construit la même forme dans SQL Server par `FOR JSON PATH`, en
lecture seule. Sur SQL Server 2022, il rend pour le stage 12 (deux sessions) :

    {"stageid":12,"titre":"Firebird 2.5 Développement","duree":5,"sessions":[{"sessionid":3,
    "debut":"2011-01-03","salle":13,"inscrits":[35819,63290,...]},...]}

Les données de `PachaDataFormation` viennent d'une autre génération que le portage : seule la
forme se compare.

## Les questions

1. Remplissez `outils.mv5_stage_doc` en une requête, avec `jsonb_build_object` et `jsonb_agg`
   (ou `JSON_OBJECT` et `JSON_ARRAYAGG`). Vérifiez trois cas : un stage sans session, une
   session sans inscrit, et une inscription sans contact. Que contiennent alors les tableaux ?
2. Comptez les sessions de tous les documents par `jsonb_array_length` et comparez avec
   `stage.session`. Comptez de même les couples (session, contact) des documents, par
   `JSON_TABLE` avec un `NESTED PATH`, et comparez avec les tables. Les deux comptes
   concordent-ils, et pourquoi le portage contient-il des inscriptions qui ne sont dans aucun
   document ?
3. Trouvez les stages auxquels le contact 8049 est inscrit, par `@>` sur le document, puis par
   les tables. Créez un index GIN sur la colonne : le planificateur s'en sert-il sur
   168 documents ? Comment le vérifier ?
4. Avec `JSON_TABLE`, affichez les sessions du stage 12 sous forme de lignes, avec le nombre de
   contacts de chacune.
5. Ajoutez le contact 1 à la session 208 du stage 12 dans le document. Qu'écrit PostgreSQL pour
   cette modification, comparé à un `INSERT` dans `inscription.inscription` ? Pour quel usage le
   document vaut-il mieux que les tables, et pour lequel est-ce l'inverse ?

## Le corrigé

`2-solution.sql` supprime la table de départ si elle existe, construit les documents, répond aux
questions et supprime ce qu'il a créé :

    docker compose exec db psql -U postgres -d pachadataformation -f /exercises/module_v5/2-solution.sql
