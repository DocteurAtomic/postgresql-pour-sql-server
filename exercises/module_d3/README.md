# Exercice du module D3

Restaurer une instance à la minute qui précède une erreur, vérifier ce qu'on récupère, puis
ramener sur l'instance d'origine les données perdues sans défaire le reste de la journée.

Prérequis : Docker ou Podman, et le dump téléchargé par `./setup/install.sh`. L'exercice ne
touche pas au labo du cours : il se joue dans ses conteneurs, `pgd3-exercise` et
`pgd3-exercise-restore`, avec les volumes `pgd3-exercise-archive`, `pgd3-exercise-backup` et
`pgd3-exercise-data`.

## Préparation

    ./exercises/module_d3/1-start.sh

(`DOCKER=podman ./exercises/module_d3/1-start.sh` avec Podman.) Le script, qui prend environ
deux minutes, démarre `pgd3-exercise` avec l'archivage du WAL vers `/archive/wal`, y restaure
`pachadataformation`, prend une sauvegarde de base dans `/backup/nightly`, puis joue une
journée :

1. des relances sur les factures depuis 2020 ;
2. vingt secondes après le début de la minute suivante, l'erreur :
   `update stage.session set prix = 0`, sans `where` ;
3. cinq secondes plus tard, d'autres relances, légitimes.

Il affiche l'heure de chaque étape, en UTC, et la garde dans `/backup/day.txt`. Pour se
connecter :

    docker exec -it pgd3-exercise psql -U postgres -d pachadataformation

## Les questions

1. Que dit `pg_stat_archiver` ? Que contiennent `/archive/wal` et le `backup_label` de
   `/backup/nightly` ?
2. Quel instant choisir pour `recovery_target_time` ? Prenez la minute ronde qui tombe entre
   les premières relances et l'erreur.
3. Restaurez la sauvegarde de base dans une nouvelle instance, `pgd3-exercise-restore`, qui
   lit l'archive en lecture seule, et rejouez le WAL jusqu'à cette minute. Que dit le journal
   du serveur, et où s'arrête-t-il ?
4. Pendant la pause, comparez les deux instances avec `2-check.sql` : sessions à prix nul,
   prix moyen, total des relances, factures relancées aujourd'hui. Qu'est-ce que la
   restauration récupère, et qu'est-ce qu'elle perd ?
5. Terminez la restauration. Sur quelle timeline est l'instance restaurée ?
6. Ramenez les prix sur `pgd3-exercise`, sans perdre les relances faites après l'erreur.

## Le corrigé

`2-solution.sh` joue les questions 1 à 6, puis supprime les conteneurs et les volumes
(`KEEP=1 ./exercises/module_d3/2-solution.sh` pour les garder). La copie de la sauvegarde dans
un volume vide passe par la fonction `fill_volume` de `demos/module_d3/lib.sh`.

`2-check.sql` lit une instance sans la modifier ; il est marqué `ci: skip`, comme tout ce qui
demande les conteneurs de l'exercice. Ne lancez rien de ce dossier sur le labo.
