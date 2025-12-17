using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using VPChat.Core.Models;
using VPChat.Core;
using BCrypt.Net;

namespace VPChat.Core.Services
{
    public class UserService : IUserService
    {
        private readonly VPChatDbContext _context;
        private readonly string _jwtSecret;

        public UserService(VPChatDbContext context, IConfiguration configuration)
        {
            _context = context;
            _jwtSecret = configuration["Jwt:Secret"] ?? "your-super-secret-key-here-change-in-production";
        }

        public async Task<User?> RegisterAsync(string username, string password)
        {
            if (await _context.Users.AnyAsync(u => u.Username == username))
                return null; // Username exists

            var hashedPassword = BCrypt.Net.BCrypt.HashPassword(password);
            var user = new User
            {
                Username = username,
                PasswordHash = hashedPassword,
                IsOnline = false
            };

            _context.Users.Add(user);
            await _context.SaveChangesAsync();
            return user;
        }

        public async Task<string?> LoginAsync(string username, string password)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Username == username);
            if (user == null || !BCrypt.Net.BCrypt.Verify(password, user.PasswordHash))
                return null;

            user.LastSeen = DateTime.UtcNow;
            user.IsOnline = true;
            await _context.SaveChangesAsync();

            return GenerateJwtToken(user);
        }

        public async Task<User?> GetUserByUsernameAsync(string username)
        {
            return await _context.Users.FirstOrDefaultAsync(u => u.Username == username);
        }

        public async Task<User?> GetUserByIdAsync(int userId)
        {
            return await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
        }

        public async Task UpdateUserStatusAsync(int userId, bool isOnline)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
            if (user != null)
            {
                user.IsOnline = isOnline;
                user.LastSeen = DateTime.UtcNow;
                await _context.SaveChangesAsync();
            }
        }

        private string GenerateJwtToken(User user)
        {
            var tokenHandler = new JwtSecurityTokenHandler();
            var key = Encoding.UTF8.GetBytes(_jwtSecret);
            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(new[]
                {
                    new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                    new Claim(ClaimTypes.Name, user.Username!)
                }),
                Expires = DateTime.UtcNow.AddDays(30), // Increased from 7 to 30 days for development
                SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature)
            };
            var token = tokenHandler.CreateToken(tokenDescriptor);
            return tokenHandler.WriteToken(token);
        }
    }
}