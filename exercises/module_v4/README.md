# Exercice du module V4

Indexer trois requêtes lentes et mesurer le gain.

Les requêtes lisent `outils.mv4_inscription`, la table de trois millions de lignes que
génère le script de mise en place du module. Lancez-le d'abord, une fois (une quinzaine de
secondes) :

```bash
docker compose exec db psql -U postgres -d pachadataformation -f /demos/module_v4/00-setup.sql
```

## Le point de départ

`1-slow-queries.sql` contient les trois requêtes, chacune sous `explain analyze` :

1. les inscriptions d'un stagiaire qui a saisi son adresse avec des majuscules ;
2. les dix dernières annulations ;
3. les inscriptions de la première semaine de décembre 2025, par mode de financement.

```bash
docker compose exec db psql -U postgres -d pachadataformation -f /exercises/module_v4/1-slow-queries.sql
```

Pour chacune, relevez le nœud qui lit la table, `Execution Time` et la ligne `Buffers` du
nœud du haut. Écrivez ensuite l'index qui la rend rapide, en choisissant le type et la
forme d'index adaptés, puis rejouez la requête et comparez.

## Le corrigé

`2-solution.sql` crée un index par requête, rejoue les trois plans, affiche la taille des
trois index, puis les supprime.

```bash
docker compose exec db psql -U postgres -d pachadataformation -f /exercises/module_v4/2-solution.sql
```

Quand vous avez fini le module, `99-cleanup.sql` supprime la table générée :

```bash
docker compose exec db psql -U postgres -d pachadataformation -f /demos/module_v4/99-cleanup.sql
```
