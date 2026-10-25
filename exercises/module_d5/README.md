# Exercice du module D5

Trouver la session qui bloque les autres, comprendre ce qu'elle fait, et la terminer sans
toucher aux sessions qui ne sont pour rien dans le blocage.

Prérequis : le labo du cours démarré (`pgcourse`). L'exercice se joue sur le labo, dans la
base `pachadataformation` : il y crée une table à lui, `outils.md5_exercise`, et six
sessions qu'il nomme par leur `application_name`. Aucune ne dure plus de dix minutes.

## Préparation

    ./exercises/module_d5/1-start.sh

(`DOCKER=podman ./exercises/module_d5/1-start.sh` avec Podman.) Le script crée la table,
copie de `stage.session`, puis laisse six sessions en arrière-plan et rend la main. Certaines
travaillent, d'autres attendent. Pour vous connecter :

    docker compose exec db psql -U postgres -d pachadataformation

Vous avez dix minutes. Passé ce délai, ou pour recommencer, relancez `1-start.sh` : il
nettoie la scène précédente avant d'en jouer une nouvelle.

## Les questions

1. Quelles sessions la base contient-elle ? Pour chacune : son état, ce qu'elle attend, depuis
   quand sa transaction est ouverte, sa requête.
2. Lesquelles attendent un verrou, et qui les bloque d'après `pg_blocking_pids()` ?
3. La session `reporting` n'est bloquée que par `nightly-batch`. Est-ce `nightly-batch` qu'il
   faut terminer ? Trouvez la tête de la chaîne, la session qui bloque sans rien attendre
   elle-même, et comptez les sessions qui attendent derrière elle.
4. Que tient-elle dans `pg_locks` ? Que faisait-elle, et depuis combien de temps ne fait-elle
   plus rien ?
5. Essayez d'abord `pg_cancel_backend()` sur elle. Que se passe-t-il ?
6. Terminez-la avec `pg_terminate_backend()`, en filtrant sur son nom et sur la base. Que
   deviennent les autres sessions ? La colonne de `nightly-batch` a-t-elle été ajoutée ?
7. Les sessions `export` et `dashboard` étaient-elles en cause ? Quel réglage, posé par le DBA
   sur le rôle de l'application `crm`, aurait mis fin à la tête de la chaîne sans
   intervention ?

## Le corrigé

`2-solution.sql` répond aux questions 1 à 6, dans cet ordre, pendant que la scène tourne :

    docker compose exec db psql -U postgres -d pachadataformation -f /exercises/module_d5/2-solution.sql

Il ne termine que la session `crm` de cette base, et seulement si elle est inactive dans une
transaction. Lancé sans la scène, toutes ses requêtes rendent zéro ligne.

`3-reset.sql` termine ce qui reste des six sessions dans cette base, par leur nom, et
supprime la table. Les commandes `sleep` qui alimentaient `crm` et `dashboard` dans le
conteneur s'arrêtent seules au bout des dix minutes.

Pour la question 7 : `export` exécute une requête longue et `dashboard` est inactive, sans
transaction ; aucune ne tient de verrou que les autres attendent. Le réglage est
`idle_in_transaction_session_timeout`, posé par `ALTER ROLE ... SET`. Le clip D5.2 le montre
dans un conteneur à part, parce que créer un rôle et le régler touche à l'instance.
