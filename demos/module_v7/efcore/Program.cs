// ci: skip (.NET on the host, against the lab container pgcourse)
// Clip V7.4: an application that writes through Entity Framework Core. From
// demos/module_v7/efcore, with PGPASSWORD and PGDATABASE in the environment:
//   dotnet run -- seed      two feedbacks of the same trainee for session 41, in SQL
//   dotnet run -- dedupe    keeps the first of them
//   dotnet run -- local     a DateTime.Now in a timestamp with time zone column
// The schema comes from the migrations: dotnet tool restore, then dotnet ef database update.
using Microsoft.EntityFrameworkCore;

await using var db = new FeedbackContext();
switch (args.FirstOrDefault())
{
    case "seed":
        // Rows written before the next migration, by SQL: the quoted names of the model.
        var added = await db.Database.ExecuteSqlRawAsync(
            """
            insert into mv7_app."SessionFeedbacks" ("SessionId", "ContactId", "Rating", "CreatedAt")
            values (41, 1, 4, now()), (41, 1, 5, now())
            """);
        Console.WriteLine($"{added} feedbacks inserted");
        break;
    case "dedupe":
        var removed = await db.Database.ExecuteSqlRawAsync(
            """
            delete from mv7_app."SessionFeedbacks" f
            where exists (select from mv7_app."SessionFeedbacks" o
                          where o."SessionId" = f."SessionId" and o."ContactId" = f."ContactId"
                            and o."Id" < f."Id")
            """);
        Console.WriteLine($"{removed} feedback removed");
        break;
    case "local":
        db.SessionFeedbacks.Add(new SessionFeedback { SessionId = 41, ContactId = 2, Rating = 5, CreatedAt = DateTime.Now });
        try { await db.SaveChangesAsync(); }
        catch (DbUpdateException e) { Console.WriteLine($"{e.InnerException?.GetType().Name}: {e.InnerException?.Message}"); }
        catch (ArgumentException e) { Console.WriteLine($"{e.GetType().Name}: {e.Message}"); }
        db.ChangeTracker.Clear();
        db.SessionFeedbacks.Add(new SessionFeedback { SessionId = 41, ContactId = 2, Rating = 5, CreatedAt = DateTime.UtcNow });
        await db.SaveChangesAsync();
        Console.WriteLine($"with DateTime.UtcNow: {await db.SessionFeedbacks.CountAsync()} feedbacks");
        break;
}
