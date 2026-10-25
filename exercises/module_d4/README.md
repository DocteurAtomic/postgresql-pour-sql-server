# Exercice du module D4

Trouver les index redondants du portage par leur définition, puis les index inutilisés pendant
une charge rejouée par un script, et décider lesquels supprimer.

Prérequis : le labo du cours, base `pachadataformation`. L'exercice ne fait que lire : le
catalogue, et les statistiques d'activité, sans les remettre à zéro.

## Les fichiers

- `1-workload.sql` : la charge de l'application, une journée de PachaDataFormation en quelques
  secondes (recherche de contacts par nom, inscriptions d'un contact, sessions d'un stage,
  factures du jour et relances, villes d'un code postal). Il ne fait que lire.
- `2-solution.sql` : le corrigé, en une seule session.

## Les questions

1. Dans le catalogue (`pg_index`), trouvez les index B-tree non uniques dont les colonnes clés
   sont les premières colonnes d'un autre index de la même table, sans prédicat ni expression.
   Combien en trouvez-vous, et sur quelle table ?
2. Combien d'index de la base ont `idx_scan = 0` dans `pg_stat_user_indexes` ? Depuis quand
   comptent-ils (`stats_reset` dans `pg_stat_database`) ? Que vaut ce chiffre pour décider ?
3. Sans appeler `pg_stat_reset()`, mesurez l'usage des index pendant la charge : une photo des
   compteurs dans une table temporaire, la charge, la différence. Dans `psql`, `\ir
   1-workload.sql` lance la charge depuis votre script.
4. Quels index des tables touchées par la charge n'ont servi à rien ? Pour chacun, dites s'il
   garantit une contrainte (clé primaire, unicité) ou s'il sert une clé étrangère.
5. Lesquels supprimeriez-vous, et que vérifieriez-vous avant ?

## Le corrigé

Depuis le dossier du dépôt :

    docker compose exec db psql -U postgres -d pachadataformation -f /exercises/module_d4/2-solution.sql

Sur la base de l'auteur, une copie fraîche du labo :

- deux redondances, sur `inscription.facture` : `nix_facture_relance1` (`relance`), couvert par
  `nix_facture_relance2` (`relance, datefacture`), et `nix_facture_relance4` (`datefacture`),
  couvert par `nix_facture_relance3` (`datefacture, relance`) ;
- la plupart des index sont à zéro (52 sur 54 après `setup/install.sh`), et `stats_reset` est
  vide : les compteurs datent de la restauration, ils ne disent rien de l'application ;
- pendant la charge, dix index servent, et sept restent à zéro sur les tables touchées :
  `nix_adresse_02`, `nix_contact_01`, `nix_facture_relance1`, `nix_facture_relance3`,
  `pk_inscription`, `pk_ville`, `uq_sessionstage_codedatelieu` ;
- parmi eux, `pk_inscription` et `pk_ville` sont des clés primaires et
  `uq_sessionstage_codedatelieu` une contrainte d'unicité : on les garde. `nix_adresse_02`, sur
  `contact.adresse (villeid)`, sert la clé étrangère `fk_adresse_reference_ville` : sans lui,
  supprimer une ville parcourt toute la table des adresses. On le garde aussi ;
- `nix_facture_relance1` est redondant et inutilisé : c'est le candidat.
  `nix_facture_relance3` n'a pas servi à cette charge, mais il couvre `nix_facture_relance4` :
  on en garde un des deux. `nix_contact_01`, sur `contact.adressepostaleid`, ne
  sert aucune clé étrangère du portage : à vérifier avec l'équipe de l'application ;
- avant de supprimer : mesurer sur une période qui couvre les traitements rares, regarder les
  standbys (leurs compteurs sont à part), et garder la définition de l'index
  (`pg_get_indexdef`) pour le recréer.
