#!/usr/bin/env bash
# Clip D2.2: pg_hba.conf, password hashes, peer and hostssl. Runs on the host, in a
# throwaway container pgd2-hba on its own network pgd2-net (DOCKER=podman for Podman); a
# second container of the same image plays the client, as an application server would.
# Both are removed at the end. The lab is not touched. Passwords are demonstration values.
set -euo pipefail
cd "$(dirname "$0")"
docker=${DOCKER:-docker}
name=pgd2-hba
net=pgd2-net
image=docker.io/pgvector/pgvector:pg18
pgdata=/var/lib/postgresql/18/docker
cleanup() { $docker rm -f $name >/dev/null 2>&1; $docker network rm $net >/dev/null 2>&1 || true; }
trap cleanup EXIT
wait_ready() { until $docker exec $name pg_isready -U postgres -h 127.0.0.1 -q 2>/dev/null; do sleep 1; done; }
# psql as the operating system user postgres, through the socket of the container.
sql() { $docker exec -i --user postgres $name sh -c 'psql -X -v ON_ERROR_STOP=1 2>&1'; }
# A connection from inside the container, over TCP to 127.0.0.1.
inside() {
    $docker exec -e PGPASSWORD="$2" $name \
        psql -h 127.0.0.1 -U "$1" -d postgres -X -At -c "select 'connected as ' || current_user" 2>&1 || true
}
# A connection from another container, as an application server would make it.
client() {
    $docker run --rm --network $net -e PGPASSWORD="$2" $image \
        psql "host=$name user=$1 dbname=postgres ${3:-}" -X -At \
        -c "select 'connected as ' || current_user || ', ssl ' || ssl || coalesce(' ' || version, '')
            from pg_stat_ssl where pid = pg_backend_pid()" 2>&1 || true
}
# The server log since the last mark: what pg_hba.conf line decided, and why it failed.
mark() { seen=$($docker logs $name 2>&1 | wc -l); }
auth_log() {
    sleep 1
    $docker logs $name 2>&1 | tail -n +$((seen + 1)) | grep -A1 'md2_' \
        | grep -oE '(connection authenticated|FATAL|DETAIL).*' || true
}
reload() { echo "select pg_reload_conf();" | sql >/dev/null; sleep 1; }

$docker network create $net >/dev/null
$docker run -d --name $name --network $net -e POSTGRES_PASSWORD=course $image \
    -c log_connections=authentication >/dev/null
wait_ready

echo "== 1. two roles, one password hashed in SCRAM, one in MD5"
sql <<'SQL'
create role md2_app login password 'demo-app';
set password_encryption = 'md5';
create role md2_old login password 'demo-old';
reset password_encryption;
select rolname, case when rolpassword like 'md5%' then 'md5'
                    else split_part(rolpassword, '$', 1) end as hash
from pg_authid where rolname like 'md2%' order by 1;
SQL

echo "== 2. the pg_hba.conf of the image: inside the container, a wrong password is enough"
inside md2_app wrong-password
echo "== from another container, the password is checked"
client md2_app wrong-password
client md2_app demo-app

echo "== 3. a pg_hba.conf of our own: peer for postgres, passwords everywhere else"
$docker exec -i $name sh -c "cat > $pgdata/pg_hba.conf" <<'HBA'
# TYPE  DATABASE  USER      ADDRESS   METHOD
local   all       postgres            peer
local   all       all                 scram-sha-256
host    all       md2_app   all       md5
host    all       all       all       scram-sha-256
HBA
echo "select line_number, type, user_name, address, auth_method, error from pg_hba_file_rules order by rule_number;" | sql
reload
mark
inside md2_app wrong-password
inside md2_app demo-app
auth_log
echo "== the MD5 hash on a scram-sha-256 line"
mark
client md2_old demo-old
auth_log
echo "alter role md2_old password 'demo-old';" | sql
client md2_old demo-old

echo "== 4. peer: the operating system user must be the role"
$docker exec $name psql -U postgres -X -At -c "select 'connected as ' || current_user" 2>&1 || true
$docker exec --user postgres $name psql -U postgres -X -At -c "select 'connected as ' || current_user"

echo "== 5. hostssl: TLS with a self-signed certificate"
$docker exec --user postgres $name sh -c "cd $pgdata && openssl req -new -x509 -days 30 -nodes -subj /CN=$name \
    -out server.crt -keyout server.key 2>/dev/null && chmod 600 server.key"
echo "alter system set ssl = on;" | sql
$docker exec $name sed -i 's/^host    all       all       all       scram-sha-256/hostssl all       all       all       scram-sha-256/' $pgdata/pg_hba.conf
reload
echo "select line_number, type, user_name, auth_method from pg_hba_file_rules order by rule_number;" | sql
client md2_old demo-old "sslmode=disable"
client md2_old demo-old
