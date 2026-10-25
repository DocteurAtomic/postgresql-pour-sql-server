# ci: skip (Python on the host, against the lab container pgcourse)
# Clip V7.1: psycopg 3, the Python driver, over libpq. The connection string is a libpq
# string; the password comes from PGPASSWORD, as for psql.
#   uv run --with 'psycopg[binary]' python demos/module_v7/01-connect.py
import os
import psycopg

conninfo = "host=127.0.0.1 port=5432 dbname={} user=postgres application_name=pachadata-psycopg".format(
    os.environ.get("PGDATABASE", "pachadataformation"))
session = """select a.application_name, a.client_addr::text, s.ssl
             from pg_stat_activity a join pg_stat_ssl s using (pid)
             where a.pid = pg_backend_pid()"""
for mode in ("prefer", "require"):
    try:
        with psycopg.connect(conninfo, sslmode=mode) as conn:
            print(f"sslmode={mode}:", conn.execute(session).fetchone())
    except psycopg.OperationalError as e:
        print(f"sslmode={mode}: {type(e).__name__}: {str(e).strip()}")
