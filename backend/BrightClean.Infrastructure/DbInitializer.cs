using Microsoft.EntityFrameworkCore;

namespace BrightClean.Infrastructure
{
    public static class DbInitializer
    {
        public static void Seed(AppDbContext context)
        {
            context.Database.Migrate();
        }
    }
}
