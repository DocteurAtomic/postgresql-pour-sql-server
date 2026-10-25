#!/usr/bin/env bash
# Clip D5.5: three monitoring tools around a throwaway instance under a pgbench load:
# postgres_exporter (image quay.io/prometheuscommunity/postgres-exporter, Prometheus
# community), Prometheus (image prom/prometheus) and pgBadger (PGDG package installed in
# the instance's container). Runs on the host (DOCKER=podman for Podman); the containers
# pgd5-monitor, pgd5-exporter and pgd5-prometheus and the network pgd5-net are removed at
# the end. The lab is not touched.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
exporter_image=quay.io/prometheuscommunity/postgres-exporter:v0.20.1
prometheus_image=docker.io/prom/prometheus:v3.15.0
c=pgd5-monitor
cleanup() {
    $docker rm -f $c pgd5-exporter pgd5-prometheus >/dev/null 2>&1 || true
    $docker network rm pgd5-net >/dev/null 2>&1 || true
}
trap cleanup EXIT
$docker network create pgd5-net >/dev/null

echo "== 1. an instance that logs what pgBadger reads, and a role for the exporter"
$docker run -d --name $c --network pgd5-net -e POSTGRES_PASSWORD=course $image postgres \
    -c shared_preload_libraries=pg_stat_statements -c logging_collector=on \
    -c "log_line_prefix=%t [%p]: user=%u,db=%d,app=%a,client=%h " -c lc_messages=C \
    -c log_min_duration_statement=0 -c log_checkpoints=on -c log_connections=on \
    -c log_disconnections=on -c log_lock_waits=on -c log_temp_files=0 \
    -c log_autovacuum_min_duration=0 >/dev/null
wait_ready $c
sql $c -q -c "create role md5_exporter login password 'md5-demo' in role pg_monitor"
$docker exec $c pgbench -U postgres -i -s 10 -q postgres 2>&1 | tail -1

echo "== 2. postgres_exporter, connected as a member of pg_monitor"
$docker run -d --name pgd5-exporter --network pgd5-net \
    -e DATA_SOURCE_URI="$c:5432/postgres?sslmode=disable" \
    -e DATA_SOURCE_USER=md5_exporter -e DATA_SOURCE_PASS=md5-demo $exporter_image >/dev/null
cat > /tmp/pgd5-prometheus.yml <<'YML'
global:
  scrape_interval: 5s
scrape_configs:
  - job_name: postgres
    static_configs:
      - targets: ['pgd5-exporter:9187']
YML
$docker run -d --name pgd5-prometheus --network pgd5-net \
    -v /tmp/pgd5-prometheus.yml:/etc/prometheus/prometheus.yml:ro,Z $prometheus_image >/dev/null
rm -f /tmp/pgd5-prometheus.yml
sleep 3

echo "== 3. a load: pgbench, 4 clients, 20 seconds, in the background"
$docker exec $c pgbench -U postgres -c 4 -j 2 -T 20 -P 5 postgres > /tmp/pgd5-pgbench.txt 2>&1 &
sleep 12

echo "== 4. during the load, what the exporter publishes (a few of its metrics)"
$docker exec pgd5-exporter wget -qO- http://localhost:9187/metrics |
    grep -E '^(pg_up|pg_stat_database_xact_commit\{.*datname="postgres"|pg_stat_activity_count\{.*state="active".*usename="postgres"|pg_settings_max_connections|pg_database_size_bytes\{datname="postgres")' |
    sed -E 's/application_name="",//' | sort
echo "metrics published: $($docker exec pgd5-exporter wget -qO- http://localhost:9187/metrics | grep -vc '^#')"

echo "== 5. during the load, Prometheus: commits per second over the last 10 s"
q='rate(pg_stat_database_xact_commit{datname="postgres"}[10s])'
$docker exec pgd5-prometheus wget -qO- "http://localhost:9090/api/v1/query?query=$(printf %s "$q" | sed 's/{/%7B/g; s/}/%7D/g; s/"/%22/g; s/\[/%5B/g; s/\]/%5D/g; s/=/%3D/g')" |
    grep -oE '"value":\[[^]]*\]'
wait
grep -E '^(progress|tps|number of transactions actually)' /tmp/pgd5-pgbench.txt
rm -f /tmp/pgd5-pgbench.txt

echo "== 6. pgBadger, from the PGDG repository, on the log of the instance"
$docker exec $c sh -c 'apt-get update -qq >/dev/null && apt-get install -y -qq pgbadger >/dev/null 2>&1; pgbadger --version'
$docker exec $c sh -c 'cd /var/lib/postgresql/18/docker/log && ls -sh && pgbadger -q -x text -o /tmp/report.txt *.log'
$docker exec $c sh -c "grep -A 14 -E '^- Overall statistics' /tmp/report.txt"
$docker exec $c sh -c "sed -n '/^- Queries that took up the most time (N)/,/^- Most frequent queries/p' /tmp/report.txt" |
    grep -E '^(- Queries|Rank|[0-9]+\))' | awk 'NR <= 5' | cut -c1-110
