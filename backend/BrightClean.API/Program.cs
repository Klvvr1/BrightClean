using Microsoft.EntityFrameworkCore;
using BrightClean.Infrastructure;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers().AddJsonOptions(options =>
{
    options.JsonSerializerOptions.ReferenceHandler = System.Text.Json.Serialization.ReferenceHandler.IgnoreCycles;
    options.JsonSerializerOptions.Converters.Add(new System.Text.Json.Serialization.JsonStringEnumConverter());
});

// Configure JWT Authentication
var secretKey = builder.Configuration["Jwt:Key"];
if (string.IsNullOrEmpty(secretKey))
{
    throw new InvalidOperationException("JWT signing key is not configured. Set Jwt:Key in user secrets (dotnet user-secrets set \"Jwt:Key\" \"<your-key>\") or environment variables.");
}
var key = Encoding.UTF8.GetBytes(secretKey);

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false;
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(key),
        ValidateIssuer = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"] ?? "BrightCleanBackend",
        ValidateAudience = true,
        ValidAudience = builder.Configuration["Jwt:Audience"] ?? "BrightCleanClients",
        ValidateLifetime = true,
        ClockSkew = TimeSpan.Zero
    };
});

// Register AppDbContext with SQL Server connection string
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection"),
        b => b.MigrationsAssembly("BrightClean.API")));

// Configure Swagger with JWT Bearer Security Scheme
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "BrightClean API", Version = "v1" });
    
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT Authorization header using the Bearer scheme. Example: \"Authorization: Bearer {token}\"",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                },
                Scheme = "oauth2",
                Name = "Bearer",
                In = ParameterLocation.Header
            },
            new System.Collections.Generic.List<string>()
        }
    });
});

var app = builder.Build();

// Run database seeding (only in Development or when configured)
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    var env = services.GetRequiredService<IHostEnvironment>();
    var config = services.GetRequiredService<IConfiguration>();

    var shouldSeed = env.IsDevelopment() || config.GetValue<bool>("Database:SeedOnStartup", false);

    if (shouldSeed)
    {
        try
        {
            var context = services.GetRequiredService<AppDbContext>();
            var logger = services.GetRequiredService<ILogger<Program>>();
            DbInitializer.Seed(context);
        }
        catch (Exception ex)
        {
            var logger = services.GetRequiredService<ILogger<Program>>();
            logger.LogError(ex, "An error occurred while seeding the database.");
        }
    }
}

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

if (!app.Environment.IsDevelopment() ||
    app.Configuration.GetValue<bool>("Security:UseHttpsRedirectionInDevelopment", false))
{
    app.UseHttpsRedirection();
}

// SECURITY NOTE: Static file serving exposes KYC uploads in wwwroot/uploads
// TODO: Move uploads to a protected directory (outside wwwroot) and implement
// an authenticated download endpoint to serve files with proper access control.
// See Issue #4 for full implementation requirements.
app.UseStaticFiles();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
