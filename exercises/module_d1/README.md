# Exercice du module D1

Régler une instance limitée à 4 Go de mémoire, prévoir les réglages qui demandent un
redémarrage, le vérifier, puis tout défaire.

Prérequis : Docker ou Podman. L'exercice ne touche pas au labo du cours : il se joue dans un
conteneur à lui, `pgd1-exercise`, avec son volume `pgd1-exercise-data`.

## Préparation

    ./exercises/module_d1/1-start.sh

(`DOCKER=podman ./exercises/module_d1/1-start.sh` avec Podman.) Le script démarre
l'instance avec `--memory 4g` et `--shm-size 256m`. Pour s'y connecter :

    docker exec -it pgd1-exercise psql -U postgres

## Les questions

1. Combien de mémoire l'instance peut-elle utiliser ? Comparez `/proc/meminfo` et
   `/sys/fs/cgroup/memory.max` dans le conteneur (`docker exec pgd1-exercise cat ...`).
2. Pour `shared_buffers`, `max_connections`, `effective_cache_size`, `work_mem`,
   `maintenance_work_mem`, `autovacuum_work_mem` et `log_min_duration_statement`, relevez le
   contexte dans `pg_settings`, et prévoyez lesquels demanderont un redémarrage.
3. Choisissez des valeurs pour une instance dédiée de 4 Go qui accepte au plus 50
   connexions, et appliquez-les par `ALTER SYSTEM`. Rechargez la configuration. Lesquels ont
   `pending_restart` à vrai ?
4. Redémarrez le conteneur (`docker restart pgd1-exercise`) et vérifiez que tout est
   appliqué. Calculez la mémoire de `shared_buffers`, celle d'un tri par connexion, et le
   maximum de l'autovacuum. Le total tient-il dans 4 Go ?
5. Défaites tout par `ALTER SYSTEM RESET ALL` et rechargez. Qu'est-ce qui revient tout de
   suite, et qu'est-ce qui attend encore un redémarrage ?

## Le corrigé

`2-solution.sh` joue tout l'exercice, de la question 1 à la question 5, puis supprime le
conteneur et son volume (`KEEP=1 ./exercises/module_d1/2-solution.sh` pour les garder). Il
lit `2-solution.sql` (questions 2 et 3), `2-after-restart.sql` (question 4) et
`3-reset.sql` (question 5), qui se jouent aussi à la main :

    docker exec -i pgd1-exercise psql -U postgres -X < exercises/module_d1/2-solution.sql

Ces trois scripts changent l'instance : ils sont marqués `ci: skip`, et l'intégration
continue du dépôt ne les joue pas. Ne les lancez pas sur le labo.
