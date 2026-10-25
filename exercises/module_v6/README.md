# Exercice du module V6

Écrire une recherche de stages qui tolère les fautes de frappe et l'absence d'accents, sur
les titres de `stage.stagelangue`, et l'indexer.

Prérequis : le labo démarré (`./setup/install.sh`), la base `pachadataformation` restaurée.

## Point de départ

`1-setup.sql` crée les extensions `pg_trgm`, `unaccent` et `fuzzystrmatch` si elles
manquent, et la table `outils.mv6x_stage`, les 168 titres de stage en français :

    docker compose exec db psql -U postgres -d pachadataformation -f /exercises/module_v6/1-setup.sql

Il compte aussi les titres qui répondent à `ilike '%developpement%'` : aucun, faute d'accent.

## Les questions

1. Écrivez une fonction `outils.mv6x_normalize(text)` qui retire les accents et passe en
   minuscules, et qui puisse servir dans un index. Pourquoi ne pouvez-vous pas indexer
   directement `lower(unaccent(titre))` ? Combien de titres contiennent maintenant
   `developpement` ?
2. Créez sur les titres normalisés l'index de trigrammes qui sert à la fois `%` et le tri
   par `<->`. Lequel des deux types d'index, GIN ou GiST, faut-il ? Vérifiez dans le plan
   qu'il sert le tri (sur 168 lignes, le planificateur préfère lire la table : désactivez
   `enable_seqscan` le temps du `EXPLAIN`).
3. Écrivez `outils.mv6x_search(p_query text, p_limit integer default 5)`, qui rend
   `stageid`, `titre` et la similarité arrondie à deux décimales, les titres les plus proches
   d'abord.
4. Jouez-la sur `postgre optimisation`, `devlopement mysql`, `sql serveur avance` et
   `firebird decouverte`, trois résultats chacune. Lesquelles trouvent ce que l'utilisateur
   cherchait ? Laquelle mélange deux produits ?
5. Pourquoi `soundex` ne conviendrait pas ici ? Comptez les codes distincts sur les 168
   titres.

## Le corrigé

- `2-solution.sql` répond aux cinq questions : la fonction enveloppe `IMMUTABLE`, l'index
  `gist (outils.mv6x_normalize(titre) gist_trgm_ops)`, la fonction de recherche et les
  quatre requêtes.
- `3-cleanup.sql` supprime la table, les deux fonctions et les trois extensions.

      docker compose exec db psql -U postgres -d pachadataformation -f /exercises/module_v6/2-solution.sql
      docker compose exec db psql -U postgres -d pachadataformation -f /exercises/module_v6/3-cleanup.sql

Sur le labo, 21 titres contiennent `developpement` une fois normalisés ; les quatre
recherches trouvent en tête PostgreSQL Optimisation (0,74), MySQL Développement (0,56),
SQL Server 7 Avancé (0,68) et Firebird Découverte (0,83), et `firebird decouverte` ramène
en troisième MySQL 4.0 Découverte (0,37). Les 168 titres n'ont que huit codes Soundex : le
code ne retient que le début de la chaîne, et les 24 stages PostgreSQL ont celui de
`postgre optimisation`.
