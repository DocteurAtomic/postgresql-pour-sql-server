# Exercice du module D6

Monter un standby d'un primaire fourni, mesurer son retard pendant une rafale d'écritures, puis
le promouvoir et traiter ce que l'ancien primaire garde.

Prérequis : Docker ou Podman, et le dump téléchargé par `./setup/install.sh`. L'exercice ne
touche pas au labo du cours : il se joue dans ses conteneurs, `pgd6-exercise-primary` et
`pgd6-exercise-standby`, sur le réseau `pgd6-net`, avec les volumes
`pgd6-exercise-primary-data` et `pgd6-exercise-standby-data`.

## Préparation

    ./exercises/module_d6/1-start.sh

(`DOCKER=podman ./exercises/module_d6/1-start.sh` avec Podman.) Le script démarre
`pgd6-exercise-primary`, y restaure `pachadataformation`, et crée le rôle `replicator`
(attribut `REPLICATION`, mot de passe `replication-demo`) avec sa ligne `pg_hba.conf`. Pour se
connecter :

    docker exec -it pgd6-exercise-primary psql -U postgres -d pachadataformation

Les fonctions de `demos/module_d6/lib.sh` (`make_standby`, `wait_replayed`) peuvent servir, mais
l'exercice se fait mieux à la main, avec un conteneur jetable sur le réseau `pgd6-net` pour
`pg_basebackup`, comme dans `demos/module_d6/02-standby.sh`. Le répertoire de données de l'image
est `/var/lib/postgresql/18/docker`, dans un volume monté sur `/var/lib/postgresql`.

## Les questions

1. Clonez le primaire dans le volume `pgd6-exercise-standby-data` avec `pg_basebackup`, de façon
   à obtenir un standby qui utilise un slot de réplication nommé `standby1`. Démarrez
   `pgd6-exercise-standby` sur ce volume. Quels fichiers montrent que c'est un standby ?
2. Que disent `3-lag-primary.sql` sur le primaire et `3-lag-standby.sql` sur le standby ?
3. Mettez le rejeu en pause sur le standby (`pg_wal_replay_pause()`), puis lancez `2-load.sql` sur
   le primaire. Que disent les deux scripts de mesure ? La table `outils.md6x_load` est-elle
   visible sur le standby ? Reprenez le rejeu (`pg_wal_replay_resume()`) et mesurez de nouveau.
4. Arrêtez le primaire, comme une panne, et promouvez le standby. Sur quelle timeline est-il ?
   Accepte-t-il les écritures ? Redémarrez ensuite l'ancien primaire seul : que reste-t-il dans
   son `pg_replication_slots`, et qu'en faire ?

Pour finir :

    ./exercises/module_d6/9-stop.sh

## Le corrigé

`4-solution.sh` joue les questions 1 à 4 depuis le départ, puis supprime conteneurs, volumes et
réseau (`KEEP=1 ./exercises/module_d6/4-solution.sh` pour les garder). Les scripts `.sql` de ce
dossier sont marqués `ci: skip` : ils se jouent sur les conteneurs de l'exercice, jamais sur le
labo.
