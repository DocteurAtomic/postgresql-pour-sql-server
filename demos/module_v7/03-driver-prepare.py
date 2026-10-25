# ci: skip (Python on the host, against the lab container pgcourse)
# Clip V7.3: what psycopg 3 sends for a parameterized query, and the plans PostgreSQL makes
# of it. auto_explain, loaded in the session, sends each plan back as a NOTICE: the script
# prints its scan node and condition. The password comes from PGPASSWORD.
#   PGPASSWORD=course uv run --with 'psycopg[binary]' python demos/module_v7/03-driver-prepare.py
import os
import psycopg

QUERY = "select count(*), sum(montantttc) from inscription.facture where relance = %s"
CONNINFO = "host=127.0.0.1 port=5432 dbname={} user=postgres application_name=pachadata-psycopg".format(
    os.environ.get("PGDATABASE", "pachadataformation"))


def session(options=""):
    conn = psycopg.connect(CONNINFO, options=options, autocommit=True)
    plans = []
    conn.add_notice_handler(lambda notice: plans.append(notice.message_primary))
    for setting in ("load 'auto_explain'", "set auto_explain.log_min_duration = 0",
                    "set auto_explain.log_analyze = on", "set auto_explain.log_timing = off",
                    "set auto_explain.log_level = notice"):
        conn.execute(setting, prepare=False)
    plans.clear()
    return conn, plans


def run(conn, plans, values):
    for i, value in enumerate(values, start=1):
        plans.clear()
        count, _ = conn.execute(QUERY, (value,)).fetchone()
        # The scan node: estimated and actual rows, and the condition (value or $1).
        lines = [l.strip() for p in plans for l in p.splitlines()]
        scan = next(l for l in lines if "Scan" in l and "Bitmap Index" not in l)
        cond = next(l for l in lines if "Cond:" in l)
        node = scan.split("  (")[0].lstrip("-> ")
        est = scan.split("rows=")[1].split()[0]
        act = scan.split("rows=")[2].split()[0]
        stmts = conn.execute(
            "select name, generic_plans, custom_plans from pg_prepared_statements "
            "where statement like '%%facture%%'", prepare=False).fetchall()
        print(f"{i:2} relance={value:<2} rows={count:<5} {node}, estimated {est}, actual {act}, {cond}  prepared: {stmts}")


conn, plans = session()
print("=== 1. psycopg defaults, prepare_threshold =", conn.prepare_threshold)
run(conn, plans, [29] * 7 + [0, 0])
conn.close()

print("=== 2. options=-c plan_cache_mode=force_generic_plan in the connection string")
conn, plans = session("-c plan_cache_mode=force_generic_plan")
run(conn, plans, [29] * 5 + [0, 0])
conn.close()
