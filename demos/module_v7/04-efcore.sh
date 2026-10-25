#!/usr/bin/env bash
# ci: skip (.NET SDK 10 on the host, against the lab container pgcourse)
# Clip V7.4: Entity Framework Core and its Npgsql provider, project demos/module_v7/efcore.
# Needs PGPASSWORD (the lab's password) in the environment. 99-cleanup.sql drops the schema
# mv7_app that the migrations create.
#   DOCKER=podman PGPASSWORD=course ./demos/module_v7/04-efcore.sh
set -uo pipefail
docker=${DOCKER:-docker}
export PGDATABASE=${DB:-pachadataformation}
cd "$(dirname "$0")/efcore"
lab() { $docker exec -i pgcourse psql -U postgres -d "$PGDATABASE" -X "$@" 2>&1; }
ef() { dotnet ef "$@" 2>&1 | grep -v -E '^(Build started|Build succeeded|The Entity Framework tools)'; }
dotnet tool restore > /dev/null && dotnet build -v q > /dev/null || exit 1

echo "=== 1. The table of the model, as the provider writes it"
ef dbcontext script | sed -n '/^CREATE TABLE/,/^);/p'
echo "=== 2. The same with UseSnakeCaseNamingConvention()"
NAMING=snake ef dbcontext script | sed -n '/^CREATE TABLE/,/^);/p'

echo "=== 3. The first migration, then the names from psql"
ef database update Initial | grep -E "^(Applying|Done)"
lab -c 'select sessionid, contactid from mv7_app.sessionfeedbacks'
lab -c 'select "SessionId", "ContactId" from mv7_app."SessionFeedbacks"'

echo "=== 4. Two feedbacks of the same trainee, then the migrations that follow"
dotnet run -- seed
ef migrations script Initial | grep -E "^(START TRANSACTION|COMMIT|ALTER|CREATE)"
ef database update | grep -E "^(Applying|Failed|Npgsql.PostgresException|Done)" | head -3
lab -c 'select "MigrationId" from mv7_app."__EFMigrationsHistory"' \
    -c "select column_name from information_schema.columns where table_schema = 'mv7_app' and table_name = 'SessionFeedbacks' and column_name = 'Source'"

echo "=== 5. Without the duplicate"
dotnet run -- dedupe
ef database update --verbose | grep -E "^(Applying|LOCK TABLE|ALTER|CREATE|Began transaction|Committed transaction|Done)" | uniq
lab -c '\d mv7_app."SessionFeedbacks"'

echo "=== 6. A local DateTime"
dotnet run -- local
lab -c 'select "ContactId", "CreatedAt", "Source" from mv7_app."SessionFeedbacks" order by "Id"'
