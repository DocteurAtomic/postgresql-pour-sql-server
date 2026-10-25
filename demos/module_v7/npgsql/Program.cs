// ci: skip (.NET on the host, against the lab container pgcourse)
// Clips V7.1 and V7.2: Npgsql, the .NET driver. Reads the password from PGPASSWORD,
// which Npgsql honors like libpq; nothing secret in the code.
// From demos/module_v7/npgsql:
//   dotnet run -- connect      application_name and SSL of the session
//   dotnet run -- pool         the cost of a connection, with and without the pool
using System.Diagnostics;
using Npgsql;

var baseCs = new NpgsqlConnectionStringBuilder
{
    Host = Environment.GetEnvironmentVariable("PGHOST") ?? "127.0.0.1",
    Port = int.Parse(Environment.GetEnvironmentVariable("PGPORT") ?? "5432"),
    Database = Environment.GetEnvironmentVariable("PGDATABASE") ?? "pachadataformation",
    Username = Environment.GetEnvironmentVariable("PGUSER") ?? "postgres",
    ApplicationName = "pachadata-npgsql",
};

switch (args.FirstOrDefault() ?? "connect")
{
    case "connect":
        await ShowSession(baseCs.ConnectionString);
        // The lab has no TLS: Require refuses to connect instead of falling back.
        var strict = new NpgsqlConnectionStringBuilder(baseCs.ConnectionString) { SslMode = SslMode.Require };
        try { await ShowSession(strict.ConnectionString); }
        catch (Exception e) { Console.WriteLine($"SSL Mode=Require: {e.GetType().Name}: {e.Message}"); }
        break;
    case "pool":
        await OpenClose(new NpgsqlConnectionStringBuilder(baseCs.ConnectionString) { Pooling = false }, 200);
        await OpenClose(new NpgsqlConnectionStringBuilder(baseCs.ConnectionString) { Pooling = true }, 200);
        await ResetOnReturn(baseCs);
        break;
}

static async Task ShowSession(string cs)
{
    await using var conn = new NpgsqlConnection(cs);
    await conn.OpenAsync();
    await using var cmd = new NpgsqlCommand(
        """
        select a.application_name, a.client_addr::text, s.ssl
        from pg_stat_activity a join pg_stat_ssl s using (pid)
        where a.pid = pg_backend_pid()
        """, conn);
    await using var r = await cmd.ExecuteReaderAsync();
    await r.ReadAsync();
    Console.WriteLine($"SSL Mode={new NpgsqlConnectionStringBuilder(cs).SslMode}: application_name={r.GetString(0)} client_addr={r.GetString(1)} ssl={r.GetBoolean(2)}");
}

// Opens, queries and closes a connection n times.
static async Task OpenClose(NpgsqlConnectionStringBuilder csb, int n)
{
    var sw = Stopwatch.StartNew();
    for (var i = 0; i < n; i++)
    {
        await using var conn = new NpgsqlConnection(csb.ConnectionString);
        await conn.OpenAsync();
        await using var cmd = new NpgsqlCommand("select 1", conn);
        await cmd.ExecuteScalarAsync();
    }
    sw.Stop();
    Console.WriteLine($"Pooling={csb.Pooling}: {n} open/close in {sw.ElapsedMilliseconds} ms, {sw.Elapsed.TotalMilliseconds / n:F2} ms each");
}

// A setting made on a pooled connection does not follow it back into the pool.
static async Task ResetOnReturn(NpgsqlConnectionStringBuilder csb)
{
    var cs = new NpgsqlConnectionStringBuilder(csb.ConnectionString) { MaxPoolSize = 1 }.ConnectionString;
    await using (var conn = new NpgsqlConnection(cs))
    {
        await conn.OpenAsync();
        await using var set = new NpgsqlCommand("set work_mem = '256MB'", conn);
        await set.ExecuteNonQueryAsync();
        await using var pid = new NpgsqlCommand("select pg_backend_pid()", conn);
        Console.WriteLine($"first use:  pid {await pid.ExecuteScalarAsync()}, work_mem 256MB");
    }
    await using (var conn = new NpgsqlConnection(cs))
    {
        await conn.OpenAsync();
        await using var cmd = new NpgsqlCommand("select pg_backend_pid(), current_setting('work_mem')", conn);
        await using var r = await cmd.ExecuteReaderAsync();
        await r.ReadAsync();
        Console.WriteLine($"second use: pid {r.GetInt32(0)}, work_mem {r.GetString(1)}");
    }
}
