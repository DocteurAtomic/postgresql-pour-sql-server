# PostgreSQL pour les professionnels de SQL Server

Labo, démonstrations et exercices du cours en ligne
[« PostgreSQL pour les professionnels de SQL Server »](https://www.docteuratomic.com) de
Docteur Atomic.

## Le labo

Il faut Docker (ou Podman) avec `compose`, `curl` et un shell bash (sous Windows, WSL ou
Git Bash).

    git clone https://github.com/DocteurAtomic/postgresql-pour-sql-server.git
    cd postgresql-pour-sql-server
    ./setup/install.sh

Le script télécharge la sauvegarde de la base `pachadataformation` (24 Mo), vérifie sa
somme SHA-256, démarre PostgreSQL 18 dans le conteneur `pgcourse` et restaure la base. Avec
Podman : `COMPOSE="podman compose" ./setup/install.sh`.

Se connecter : `docker compose exec db psql -U postgres -d pachadataformation`, ou depuis
DBeaver sur `localhost:5432`, utilisateur `postgres`, mot de passe `course` (un mot de
passe de labo, à ne jamais reprendre ailleurs ; `POSTGRES_PASSWORD` et `PGPORT` le
changent avant le premier démarrage).

## Le contenu

- `demos/module_XX` : les scripts joués dans les vidéos du module, dans l'ordre de leur
  numéro. `00-setup.sql`, quand il existe, prépare le module et `99-cleanup.sql` supprime
  ce qu'il a créé. L'en-tête de chaque script dit où il se joue.
- `exercises/module_XX` : les fichiers de l'exercice du module, corrigé compris.
- `setup/run-scripts.sh` rejoue tous les scripts ; l'intégration continue le lance à
  chaque modification.

Les modules `01` à `05` forment le tronc commun, `v1` à `v7` le parcours développeur,
`d1` à `d8` le parcours DBA.

Jouez ces scripts sur le labo, jamais sur un serveur de production : certains changent la
configuration de l'instance.

## La base

`pachadataformation` est le portage PostgreSQL de la base de démonstration
PachaDataFormation de Rudi Bruchez : un organisme de formation fictif, ses stages, sessions,
inscriptions et factures. Les personnes sont fictives. La sauvegarde n'est pas dans ce dépôt,
le script la télécharge.

## Licence

Le code est sous licence MIT ([`LICENSE`](LICENSE)).

---

# PostgreSQL for SQL Server professionals

Lab, demos and exercises of the Docteur Atomic online course for SQL Server professionals
moving to PostgreSQL. Run `./setup/install.sh` (Docker or Podman with compose, curl, bash):
it downloads the `pachadataformation` dump, checks its SHA-256, starts PostgreSQL 18 and
restores the database. `demos/` holds the scripts shown in the videos and `exercises/` the
exercise files, one folder per module. The code is released under the MIT license.
