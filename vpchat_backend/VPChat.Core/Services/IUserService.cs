using VPChat.Core.Models;

namespace VPChat.Core.Services
{
    public interface IUserService
    {
        Task<User?> RegisterAsync(string username, string password);
        Task<string?> LoginAsync(string username, string password);
        Task<User?> GetUserByUsernameAsync(string username);
        Task<User?> GetUserByIdAsync(int userId);
        Task UpdateUserStatusAsync(int userId, bool isOnline);
    }
}