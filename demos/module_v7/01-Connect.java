// ci: skip (Java on the host, against the lab container pgcourse)
// Clip V7.1: pgjdbc, the Java driver, written in Java without libpq. The URL is a JDBC URL;
// the password comes from the PGPASSWORD environment variable, read by the code.
//   java -cp postgresql-42.7.14.jar demos/module_v7/01-Connect.java
// (the driver jar from https://jdbc.postgresql.org/download/ or Maven Central)
import java.sql.*;
import java.util.Properties;

public class Connect {
    public static void main(String[] args) throws Exception {
        String db = System.getenv().getOrDefault("PGDATABASE", "pachadataformation");
        String session = "select a.application_name, a.client_addr::text, s.ssl "
            + "from pg_stat_activity a join pg_stat_ssl s using (pid) where a.pid = pg_backend_pid()";
        for (String url : new String[] {
                "jdbc:postgresql://127.0.0.1:5432/" + db,
                "jdbc:postgresql://127.0.0.1:5432/" + db + "?ApplicationName=pachadata-pgjdbc&sslmode=require" }) {
            Properties p = new Properties();
            p.setProperty("user", "postgres");
            p.setProperty("password", System.getenv("PGPASSWORD"));
            try (Connection c = DriverManager.getConnection(url, p);
                 Statement s = c.createStatement(); ResultSet r = s.executeQuery(session)) {
                r.next();
                System.out.println(url + ": " + r.getString(1) + " " + r.getString(2) + " ssl=" + r.getBoolean(3));
            } catch (SQLException e) {
                System.out.println(url + ": " + e.getSQLState() + " " + e.getMessage());
            }
        }
    }
}
