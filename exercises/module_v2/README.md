# Exercice du module V2

Réécrire en PL/pgSQL une procédure stockée T-SQL d'inscription, et lui faire vérifier ce que le
portage de la base ne vérifie plus.

Prérequis : le labo démarré (`./setup/install.sh`), la base `pachadataformation` restaurée. Pour
jouer la procédure d'origine, un SQL Server avec la base `PachaDataFormation` ; sans lui, lisez
le script et les résultats ci-dessous.

## Point de départ

`sqlserver/1-inscrire.sql` crée la base de travail `MV2PgExercise` (copies de `Contact`,
`SalleFormation`, `Session` et `Inscription`, avec les clés étrangères de SQL Server), la
procédure `dbo.Inscrire`, et l'appelle quatre fois. `sqlserver/9-cleanup.sql` supprime la base.
Sur SQL Server 2022, les appels rendent :

    open session|1|151237|0
    full session|5|151238|1
    duplicate|50002|Contact déjà inscrit à cette session.
    unknown session|547|The INSERT statement conflicted with the FOREIGN KEY constraint "fk_Inscription_Session". ...

Sur le labo, la version PL/pgSQL écrit dans une copie des inscriptions, pour que la base reste
telle qu'elle a été restaurée :

    create table outils.mv2_inscription (like inscription.inscription including all);
    insert into outils.mv2_inscription overriding system value
    select * from inscription.inscription;

## Les questions

1. Relevez dans `dbo.Inscrire` chaque construction T-SQL qui n'existe pas telle quelle dans
   PostgreSQL : les paramètres `OUTPUT`, `THROW`, `SET XACT_ABORT ON`, `BEGIN TRAN` et le
   `CATCH` qui fait le `ROLLBACK`, `WITH (UPDLOCK, HOLDLOCK)`, `SCOPE_IDENTITY()`, le type `bit`.
2. Après la copie, insérez trois lignes dans `outils.mv2_inscription`, l'une après l'autre, sans
   identifiant. Que se passe-t-il, et pourquoi ? Corrigez.
3. Écrivez la procédure `outils.mv2_inscrire` en PL/pgSQL, avec deux paramètres `OUT`. Quel code
   `SQLSTATE` choisissez-vous pour chaque `THROW` ?
4. Le portage n'a pas de clé étrangère entre `inscription.inscription` et `stage.session`. Que
   ferait votre procédure d'une session inconnue si elle se contentait de traduire le T-SQL ?
   Faites-lui vérifier la session.
5. Une session sans salle n'a pas de limite de places. Que vaut la comparaison du nombre
   d'inscrits avec `NULL` places, dans T-SQL et dans PL/pgSQL ? Vérifiez que votre procédure ne
   met pas ces inscriptions en liste d'attente.
6. Appelez la procédure pour une session qui a des places, une session pleine, une session sans
   salle, puis provoquez chaque erreur.

## Le corrigé

`2-solution.sql` crée la copie, la procédure, l'appelle, et supprime ce qu'il a créé :

    docker compose exec db psql -U postgres -d pachadataformation -f /exercises/module_v2/2-solution.sql
