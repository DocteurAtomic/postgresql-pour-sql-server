// Clip V7.4: an Entity Framework Core model on PostgreSQL, through the Npgsql provider.
using Microsoft.EntityFrameworkCore;

public class SessionFeedback
{
    public int Id { get; set; }
    public int SessionId { get; set; }
    public int ContactId { get; set; }
    public short Rating { get; set; }
    public string? Comment { get; set; }
    public DateTime CreatedAt { get; set; }
    public string Source { get; set; } = "web";
}

public class FeedbackContext : DbContext
{
    public DbSet<SessionFeedback> SessionFeedbacks => Set<SessionFeedback>();

    protected override void OnConfiguring(DbContextOptionsBuilder options)
    {
        // No password here: Npgsql reads PGPASSWORD, like libpq.
        var db = Environment.GetEnvironmentVariable("PGDATABASE") ?? "pachadataformation";
        options.UseNpgsql($"Host=127.0.0.1;Port=5432;Database={db};Username=postgres;Application Name=pachadata-efcore",
            npgsql => npgsql.MigrationsHistoryTable("__EFMigrationsHistory", "mv7_app"));
        // NAMING=snake: names that PostgreSQL folds to lower case, without quotes.
        if (Environment.GetEnvironmentVariable("NAMING") == "snake")
            options.UseSnakeCaseNamingConvention();
    }

    protected override void OnModelCreating(ModelBuilder model)
    {
        model.HasDefaultSchema("mv7_app");
        var feedback = model.Entity<SessionFeedback>();
        feedback.Property(f => f.Source).HasDefaultValue("web");
        // One feedback per trainee and per session (migration OneFeedbackPerTrainee).
        feedback.HasIndex(f => new { f.SessionId, f.ContactId }).IsUnique();
        // Built without blocking the writes, outside the transaction (migration ContactIndex).
        feedback.HasIndex(f => f.ContactId).IsCreatedConcurrently();
    }
}
