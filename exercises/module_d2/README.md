# Exercice du module D2

Donner à une application et à un analyste les seuls droits qu'il leur faut, puis le
vérifier en prenant leur identité.

L'exercice se joue sur le labo, dans la base `pachadataformation`. Les rôles sont des objets
de l'instance : `4-cleanup.sql` les supprime, avec tout ce qui leur a été accordé.

## Préparation

    docker compose exec db psql -U postgres -d pachadataformation -f /exercises/module_d2/1-start.sql

Le script crée deux rôles qui peuvent se connecter, `md2x_app` et `md2x_analyste`, sans aucun
privilège. Mots de passe de démonstration : ne les reprenez pas ailleurs.

## Les besoins

L'application `md2x_app` :

- lit les sessions et les stages (schéma `stage`) et les tables de référence (`reference`) ;
- inscrit un contact à une session (`INSERT` dans `inscription.inscription`), et relit
  l'identifiant de l'inscription créée (`RETURNING inscriptionid`) ;
- marque une inscription présente ou annulée (colonnes `present` et `dateannulation`) ;
- ne supprime rien, et ne lit ni les contacts ni les factures.

L'analyste `md2x_analyste` :

- lit tout ce que lit l'application dans `stage` et `reference` ;
- lit toutes les tables du schéma `inscription`, y compris celles qui y seront créées plus
  tard par `postgres` ;
- lit les contacts sans leurs données personnelles : `contactid`, `titre`, `nom`, `prenom`,
  `societeid`, et rien d'autre (ni adresse électronique, ni téléphone, ni date de naissance).

## Les questions

1. Les deux rôles partagent un besoin. Créez un rôle de groupe pour lui, plutôt que de
   répéter les `GRANT`.
2. Écrivez les `GRANT` de l'application. Quel privilège faut-il pour que `RETURNING
   inscriptionid` fonctionne ? Faut-il un droit sur la séquence de la colonne identité ?
3. Écrivez ceux de l'analyste. Pourquoi `GRANT SELECT ON ALL TABLES IN SCHEMA inscription`
   ne suffit-il pas ?
4. Vérifiez chaque besoin par `SET ROLE`, y compris ce qui doit être refusé. Annulez
   l'inscription d'essai par `ROLLBACK` : que devient la séquence de la colonne identité ?
5. Pourquoi ne pas avoir simplement donné `pg_read_all_data` à l'analyste ?

## Le corrigé

`2-solution.sql` donne les droits, `3-check.sql` les vérifie (les refus y sont attendus),
`4-cleanup.sql` supprime les rôles :

    docker compose exec db psql -U postgres -d pachadataformation -f /exercises/module_d2/2-solution.sql
    docker compose exec db psql -U postgres -d pachadataformation -f /exercises/module_d2/3-check.sql
    docker compose exec db psql -U postgres -d pachadataformation -f /exercises/module_d2/4-cleanup.sql

`3-check.sql` remet la séquence de `inscription.inscription` à sa valeur de départ : un
`ROLLBACK` n'annule pas la consommation d'une valeur de séquence.
