# Exercice du module V7

Observer, dans `pg_prepared_statements`, les plans personnalisés et le plan générique d'une
requête préparée, puis forcer le plan générique et mesurer ce qu'il coûte.

Prérequis : le labo démarré (`./setup/install.sh`), la base `pachadataformation` restaurée.

## Point de départ

`1-setup.sql` crée l'extension `pg_stat_statements` si elle manque. Le labo charge déjà sa
bibliothèque au démarrage (`shared_preload_libraries`).

    docker compose exec db psql -U postgres -d pachadataformation -f /exercises/module_v7/1-setup.sql

La requête de l'exercice compte les inscriptions et les contacts d'un niveau de relance des
factures, par la jointure `inscription.facture`, `inscription.inscriptionfacture`,
`inscription.inscription`. La relance 0 couvre 6 533 factures ; les 255 autres valeurs, de
22 à 58 chacune.

Toutes les questions se jouent dans une seule session psql : l'instruction préparée et les
réglages lui appartiennent.

## Les questions

1. Préparez la requête sous le nom `enrolled_by_reminder`, avec un paramètre `smallint`
   pour la relance. Exécutez-la six fois avec la valeur 29. Combien de plans génériques et
   personnalisés `pg_prepared_statements` compte-t-il ?
2. Passez à la valeur 0, avec `explain (costs off) execute`, jusqu'à ce que la condition du
   plan s'écrive `$1`. À quelle exécution le plan générique arrive-t-il ? Pourquoi pas à la
   sixième ?
3. Comparez les deux plans pour la valeur 0, par `explain (analyze)`, avec
   `plan_cache_mode` à `force_custom_plan` puis à `force_generic_plan`. Combien de lignes
   chaque plan estime-t-il pour `facture`, combien de buffers lit-il ?
4. Exécutez 200 fois la requête avec 0 dans chaque mode, et mesurez avec
   `pg_stat_statements` (activez `pg_stat_statements.track_planning` dans la session) le
   nombre de planifications, leur temps total et le temps moyen d'exécution. Le plan
   personnalisé, qui planifie à chaque fois, coûte-t-il plus cher ?

## Le corrigé

- `2-solution.sql` répond aux quatre questions.
- `3-cleanup.sql` libère les instructions préparées de la session et supprime l'extension.

      docker compose exec db psql -U postgres -d pachadataformation -f /exercises/module_v7/2-solution.sql
      docker compose exec db psql -U postgres -d pachadataformation -f /exercises/module_v7/3-cleanup.sql

Lors de la mesure, sur le labo : après six exécutions avec 29, six plans personnalisés et
aucun générique. Les cinq premières exécutions se font toujours en plan personnalisé ; à
partir de la sixième, le planificateur compare le coût du plan générique au coût moyen des
plans personnalisés, et pour 29, ces plans bon marché l'emportent. Avec 0, les plans
personnalisés coûtent plus cher, la moyenne monte, et le générique arrive à la huitième
exécution (`generic_plans` 2, `custom_plans` 7 après les trois `explain`), avec la
condition `relance = $1`. Pour la valeur 0, le plan personnalisé estime 6 533 factures, fait
deux jointures par hachage et lit 1 555 buffers ; le plan générique en estime 65, fait une
boucle imbriquée sur `inscription`, exécutée 9 480 fois, et lit 28 712 buffers. Sur 200
exécutions, le plan personnalisé a planifié 200 fois pour 42 ms en tout, et s'exécute en
5,4 ms en moyenne ; le plan générique ne planifie jamais et s'exécute en 8,7 ms. Les temps
varient d'une machine à l'autre ; sur deux mesures, le plan personnalisé est resté le plus
rapide (5,26 et 5,42 ms contre 8,74 et 8,69).
