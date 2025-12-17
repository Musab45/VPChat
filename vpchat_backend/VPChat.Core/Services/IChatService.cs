using VPChat.Core.Models;
using VPChat.Shared.DTOs;

namespace VPChat.Core.Services
{
    public interface IChatService
    {
        // One-to-One Chat
        Task<List<ChatDto>> GetUserChatsAsync(int userId);
        Task<ChatDto> CreateOneToOneChatAsync(int userId, string targetUsername);
        Task<ChatDto?> GetChatAsync(int chatId, int userId);
        Task<bool> IsUserInChatAsync(int chatId, int userId);

        // Group Chat Management
        Task<GroupChatDto> CreateGroupChatAsync(int creatorId, string groupName, List<string>? memberUsernames = null);
        Task<GroupChatDto?> GetGroupChatAsync(int chatId, int userId);
        Task<bool> AddMemberAsync(int chatId, int requesterId, string targetUsername);
        Task<bool> RemoveMemberAsync(int chatId, int requesterId, string targetUsername);
        Task<bool> PromoteToAdminAsync(int chatId, int requesterId, string targetUsername);
        Task<bool> DemoteFromAdminAsync(int chatId, int requesterId, string targetUsername);
        Task<bool> UpdateGroupNameAsync(int chatId, int requesterId, string newName);
        Task<ChatRole?> GetUserRoleInChatAsync(int chatId, int userId);
        Task<bool> LeaveGroupAsync(int chatId, int userId);
        Task<bool> DeleteChatAsync(int chatId, int userId);
    }
}