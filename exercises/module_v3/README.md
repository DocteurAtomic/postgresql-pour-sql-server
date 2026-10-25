# Exercice du module V3

Écrire une file de traitement de factures avec `FOR UPDATE SKIP LOCKED`, la vider à deux
processus en même temps, et mesurer ce que donne la même file sans verrou.

Prérequis : le labo démarré (`./setup/install.sh`), la base `pachadataformation` restaurée.

## Point de départ

`1-setup.sql` crée dans le schéma `outils` la file `outils.mv3_invoice_queue` (les 105
factures de `inscription.facture` sans date de facture, au statut `pending`) et le journal
`outils.mv3_invoice_log` (une ligne par facture traitée et par processus) :

    docker compose exec db psql -U postgres -d pachadataformation -f /exercises/module_v3/1-setup.sql

Il se rejoue pour recharger la file.

## Les questions

1. Écrivez la requête d'un processus : elle prend les dix premières factures `pending` par
   `facturecd`, les passe à `invoiced` avec la date du jour et le nom du processus, et écrit
   une ligne par facture dans le journal. Une seule instruction suffit, avec deux CTE.
2. Ouvrez deux sessions psql. Dans chacune, ouvrez une transaction et jouez la requête.
   Quelles factures prend la seconde ? Que se passe-t-il si vous retirez `SKIP LOCKED` ?
   Et avec `NOWAIT` ?
3. Faites-en une procédure, `outils.mv3_invoice_worker(p_worker text, p_batch int)`, qui
   répète la requête, attend 0,1 seconde par lot pour simuler le travail, et valide par
   `COMMIT` après chaque lot, jusqu'à ce que la file soit vide.
4. Rechargez la file, puis appelez la procédure dans deux sessions à la fois, avec les noms
   A et B. Combien de factures chacun a-t-il traitées ? Combien de lignes a le journal ?
5. Rechargez la file, et refaites la question 4 avec une version qui lit le lot sans
   `FOR UPDATE`. Combien de factures sont journalisées deux fois ?
6. Une migration doit ajouter une colonne à la file pendant que les processus tournent.
   Que lui conseillez-vous ?

## Le corrigé

- `2-worker.sql` crée la procédure `outils.mv3_invoice_worker(p_worker, p_batch,
  p_skip_locked)` ; `p_skip_locked => false` choisit la version sans verrou.
- `3-two-workers.sh` joue les questions 4 et 5 depuis le poste (deux appels en parallèle),
  puis `4-cleanup.sql`, qui supprime les deux tables et la procédure :

      ./exercises/module_v3/3-two-workers.sh            # Docker
      DOCKER=podman ./exercises/module_v3/3-two-workers.sh

Avec `SKIP LOCKED`, le journal a 105 lignes et aucune facture n'est traitée deux fois ; sans
verrou, il en a davantage, et des factures apparaissent deux fois. La répartition entre A et
B et le nombre de doublons varient d'une exécution à l'autre.
