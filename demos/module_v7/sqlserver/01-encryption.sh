#!/usr/bin/env bash
# ci: skip (sqlcmd 18 on SQL Server, from the host)
# Clip V7.1, SQL Server side: the encryption defaults of the ODBC Driver 18, which sqlcmd 18
# uses. The password comes from SQLCMDPASSWORD in the environment, never from the command.
#   CONTAINER=sql2022 ./demos/module_v7/sqlserver/01-encryption.sh
set -uo pipefail
docker=${DOCKER:-podman}
c=${CONTAINER:-sql2022}
sqlcmd() { $docker exec -i -e SQLCMDPASSWORD="$SQLCMDPASSWORD" "$c" /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -d PachaDataFormation -W -s'|' "$@"; }
q="SET NOCOUNT ON; SELECT s.program_name, c.encrypt_option FROM sys.dm_exec_sessions AS s JOIN sys.dm_exec_connections AS c ON c.session_id = s.session_id WHERE s.session_id = @@SPID;"
echo "=== Default: encryption mandatory, certificate checked (self-signed here)"
sqlcmd -Q "$q" 2>&1
echo "=== -C: encryption, certificate trusted without check (TrustServerCertificate)"
sqlcmd -C -Q "$q" 2>&1
echo "=== -N o: encryption optional"
sqlcmd -C -N o -Q "$q" 2>&1
