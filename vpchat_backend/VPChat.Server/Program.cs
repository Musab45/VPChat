using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.Security.Claims;
using System.Text;
using VPChat.Core.Services;
using VPChat.Core;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddOpenApi();

// Add Swagger
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "VPChat API", Version = "v1" });

    // Add JWT Bearer token support
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT Authorization header using the Bearer scheme. Enter 'Bearer' [space] and then your token in the text input below. Example: 'Bearer 12345abcdef'",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT"
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
                }
            },
            Array.Empty<string>()
        }
    });
});

// Configure EF Core
builder.Services.AddDbContext<VPChatDbContext>(options =>
    options.UseSqlite(builder.Configuration.GetConnectionString("DefaultConnection"), b => b.MigrationsAssembly("VPChat.Server")));

// Configure JWT
var jwtSecret = builder.Configuration["Jwt:Secret"] ?? "your-super-secret-key-here-change-in-production";
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecret)),
            ValidateIssuer = false,
            ValidateAudience = false,
            ClockSkew = TimeSpan.Zero
        };
        
        options.Events = new JwtBearerEvents
        {
            OnAuthenticationFailed = context =>
            {
                Console.WriteLine($"Authentication failed: {context.Exception.Message}");
                Console.WriteLine($"Exception type: {context.Exception.GetType().Name}");
                if (context.Exception.InnerException != null)
                {
                    Console.WriteLine($"Inner exception: {context.Exception.InnerException.Message}");
                }
                return Task.CompletedTask;
            },
            OnTokenValidated = context =>
            {
                Console.WriteLine("Token validated successfully");
                var userId = context.Principal?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                var username = context.Principal?.FindFirst(ClaimTypes.Name)?.Value;
                Console.WriteLine($"User authenticated - ID: {userId}, Username: {username}");
                return Task.CompletedTask;
            },
            OnMessageReceived = context =>
            {
                var token = context.Token;
                if (!string.IsNullOrEmpty(token))
                {
                    Console.WriteLine($"Token received (length: {token.Length})");
                    Console.WriteLine($"Token starts with: {token.Substring(0, Math.Min(30, token.Length))}...");
                    Console.WriteLine($"Token ends with: ...{token.Substring(Math.Max(0, token.Length - 30))}");
                    
                    // Check for common issues
                    if (token.Contains(" "))
                        Console.WriteLine("WARNING: Token contains spaces!");
                    if (token.Contains("\n") || token.Contains("\r"))
                        Console.WriteLine("WARNING: Token contains newlines!");
                }
                else
                {
                    Console.WriteLine("No token received in request");
                    
                    // Check for SignalR token in query string
                    var accessToken = context.Request.Query["access_token"];
                    if (!string.IsNullOrEmpty(accessToken))
                    {
                        context.Token = accessToken;
                        Console.WriteLine("Token found in query string for SignalR");
                    }
                }
                return Task.CompletedTask;
            }
        };
    });

builder.Services.AddAuthorization();

// Add SignalR
builder.Services.AddSignalR(options =>
{
    options.EnableDetailedErrors = true; // Helpful for development
    options.KeepAliveInterval = TimeSpan.FromSeconds(15);
    options.ClientTimeoutInterval = TimeSpan.FromSeconds(30);
});

// Add CORS for SignalR and mobile access
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin() // Allow all origins for development
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
    
    // Named policy for SignalR (requires credentials)
    options.AddPolicy("SignalRPolicy", policy =>
    {
        policy.WithOrigins(
                  "http://localhost:3000", 
                  "http://localhost:5173", 
                  "http://localhost:4200",
                  "http://172.16.18.96:5014") // Your Mac's IP
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials(); // Required for SignalR
    });
});

// Register services
builder.Services.AddSingleton<IConnectionManager, ConnectionManager>(); // Singleton for connection tracking
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IChatService, ChatService>();
builder.Services.AddScoped<IMessageService, MessageService>();
builder.Services.AddScoped<IFileService, FileService>(); // Add file service

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "VPChat API v1");
    });
}

// Enable static files for test client
app.UseStaticFiles();

app.UseHttpsRedirection();

// Use CORS (must be before Authentication/Authorization)
app.UseCors();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

// Map SignalR Hub
app.MapHub<VPChat.Server.Hubs.ChatHub>("/chatHub");

app.Run();
