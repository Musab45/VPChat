using System.Linq;
using Microsoft.EntityFrameworkCore;
using VPChat.Core.Models;
using VPChat.Core;
using VPChat.Shared.DTOs;

namespace VPChat.Core.Services
{
    public class ChatService : IChatService
    {
        private readonly VPChatDbContext _context;

        public ChatService(VPChatDbContext context)
        {
            _context = context;
        }

        public async Task<Chat?> CreateOneToOneChatAsync(int userId1, int userId2)
        {
            // Check if a 1-to-1 chat already exists between these users
            var existingChat = await GetExistingOneToOneChatAsync(userId1, userId2);
            if (existingChat != null)
            {
                return existingChat;
            }

            // Create new chat
            var chat = new Chat
            {
                Type = ChatType.OneToOne,
                CreatedAt = DateTime.UtcNow,
                IsActive = true
            };

            _context.Chats.Add(chat);
            await _context.SaveChangesAsync();

            // Add participants
            var userChat1 = new UserChat
            {
                UserId = userId1,
                ChatId = chat.Id,
                JoinedAt = DateTime.UtcNow,
                Role = ChatRole.Member
            };

            var userChat2 = new UserChat
            {
                UserId = userId2,
                ChatId = chat.Id,
                JoinedAt = DateTime.UtcNow,
                Role = ChatRole.Member
            };

            _context.UserChats.AddRange(userChat1, userChat2);
            await _context.SaveChangesAsync();

            return chat;
        }

        public async Task<Chat?> GetExistingOneToOneChatAsync(int userId1, int userId2)
        {
            // Find chats where both users are participants and it's a 1-to-1 chat
            var chats = await _context.Chats
                .Where(c => c.Type == ChatType.OneToOne && c.IsActive)
                .Where(c => c.UserChats.Any(uc => uc.UserId == userId1))
                .Where(c => c.UserChats.Any(uc => uc.UserId == userId2))
                .Include(c => c.UserChats)
                .ToListAsync();

            // Verify it's exactly 2 participants
            return chats.FirstOrDefault(c => c.UserChats.Count == 2);
        }

        public async Task<IEnumerable<Chat>> GetUserChatsInternalAsync(int userId)
        {
            return await _context.Chats
                .Where(c => c.IsActive && c.UserChats.Any(uc => uc.UserId == userId))
                .Include(c => c.UserChats)
                    .ThenInclude(uc => uc.User)
                .Include(c => c.Messages.OrderByDescending(m => m.SentAt).Take(1))
                .OrderByDescending(c => c.Messages.Any() ? c.Messages.Max(m => m.SentAt) : c.CreatedAt)
                .ToListAsync();
        }

        public async Task<Chat?> GetChatByIdAsync(int chatId, int userId)
        {
            var chat = await _context.Chats
                .Include(c => c.UserChats)
                    .ThenInclude(uc => uc.User)
                .Include(c => c.Messages.OrderBy(m => m.SentAt))
                    .ThenInclude(m => m.Sender)
                .FirstOrDefaultAsync(c => c.Id == chatId && c.IsActive);

            if (chat == null || !chat.UserChats.Any(uc => uc.UserId == userId))
            {
                return null; // User is not a participant
            }

            return chat;
        }

        public async Task<bool> IsUserInChatInternalAsync(int chatId, int userId)
        {
            return await _context.UserChats
                .AnyAsync(uc => uc.ChatId == chatId && uc.UserId == userId);
        }

        // Interface implementation methods
        public async Task<List<ChatDto>> GetUserChatsAsync(int userId)
        {
            var chats = await GetUserChatsInternalAsync(userId);
            var chatDtos = new List<ChatDto>();
            foreach (var chat in chats)
            {
                chatDtos.Add(await MapToChatDtoAsync(chat, userId));
            }
            return chatDtos;
        }

        public async Task<ChatDto> CreateOneToOneChatAsync(int userId, string targetUsername)
        {
            var targetUser = await _context.Users.FirstOrDefaultAsync(u => u.Username == targetUsername);
            if (targetUser == null)
                throw new ArgumentException("Target user not found");

            var chat = await CreateOneToOneChatAsync(userId, targetUser.Id);
            if (chat == null)
                throw new InvalidOperationException("Failed to create chat");

            return await MapToChatDtoAsync(chat, userId);
        }

        public async Task<ChatDto?> GetChatAsync(int chatId, int userId)
        {
            var chat = await GetChatByIdAsync(chatId, userId);
            if (chat == null)
                return null;

            return await MapToChatDtoAsync(chat, userId);
        }

        public async Task<bool> IsUserInChatAsync(int chatId, int userId)
        {
            return await IsUserInChatInternalAsync(chatId, userId);
        }

        private async Task<ChatDto> MapToChatDtoAsync(Chat chat, int currentUserId)
        {
            var participants = await _context.UserChats
                .Where(uc => uc.ChatId == chat.Id)
                .Include(uc => uc.User)
                .Select(uc => new UserDto
                {
                    Id = uc.User.Id,
                    Username = uc.User.Username!,
                    IsOnline = uc.User.IsOnline,
                    LastSeen = uc.User.LastSeen
                })
                .ToListAsync();

            var lastMessage = await _context.Messages
                .Where(m => m.ChatId == chat.Id)
                .Include(m => m.Sender)
                .OrderByDescending(m => m.SentAt)
                .FirstOrDefaultAsync();

            MessageDto? lastMessageDto = null;
            if (lastMessage != null)
            {
                lastMessageDto = new MessageDto
                {
                    Id = lastMessage.Id,
                    ChatId = lastMessage.ChatId,
                    Sender = new UserDto
                    {
                        Id = lastMessage.Sender.Id,
                        Username = lastMessage.Sender.Username!,
                        IsOnline = lastMessage.Sender.IsOnline,
                        LastSeen = lastMessage.Sender.LastSeen
                    },
                    Content = lastMessage.Content,
                    MessageType = (int)lastMessage.MessageType,
                    FileUrl = lastMessage.FileUrl,
                    FileName = lastMessage.FileName,
                    FileSize = lastMessage.FileSize,
                    SentAt = lastMessage.SentAt,
                    Status = (int)lastMessage.Status
                };
            }

            return new ChatDto
            {
                Id = chat.Id,
                Type = (int)chat.Type,
                Name = chat.Name,
                CreatedAt = chat.CreatedAt,
                IsActive = chat.IsActive,
                Participants = participants,
                LastMessage = lastMessageDto
            };
        }

        // ============= GROUP CHAT METHODS =============

        public async Task<GroupChatDto> CreateGroupChatAsync(int creatorId, string groupName, List<string>? memberUsernames = null)
        {
            if (string.IsNullOrWhiteSpace(groupName))
                throw new ArgumentException("Group name is required");

            // Create the group chat
            var chat = new Chat
            {
                Type = ChatType.Group,
                Name = groupName,
                CreatedAt = DateTime.UtcNow,
                IsActive = true
            };

            _context.Chats.Add(chat);
            await _context.SaveChangesAsync();

            // Add creator as Creator/SuperAdmin
            var creatorUserChat = new UserChat
            {
                UserId = creatorId,
                ChatId = chat.Id,
                JoinedAt = DateTime.UtcNow,
                Role = ChatRole.Creator
            };
            _context.UserChats.Add(creatorUserChat);

            // Add initial members if provided
            if (memberUsernames != null && memberUsernames.Any())
            {
                var users = await _context.Users
                    .Where(u => u.Username != null && memberUsernames.Contains(u.Username))
                    .ToListAsync();

                foreach (var user in users)
                {
                    if (user.Id != creatorId) // Don't add creator twice
                    {
                        var userChat = new UserChat
                        {
                            UserId = user.Id,
                            ChatId = chat.Id,
                            JoinedAt = DateTime.UtcNow,
                            Role = ChatRole.Member
                        };
                        _context.UserChats.Add(userChat);
                    }
                }
            }

            await _context.SaveChangesAsync();

            // Return the created group
            return await GetGroupChatInternalAsync(chat.Id);
        }

        public async Task<GroupChatDto?> GetGroupChatAsync(int chatId, int userId)
        {
            // Verify user is in the chat
            if (!await IsUserInChatInternalAsync(chatId, userId))
                return null;

            var chat = await _context.Chats
                .FirstOrDefaultAsync(c => c.Id == chatId && c.Type == ChatType.Group && c.IsActive);

            if (chat == null)
                return null;

            return await GetGroupChatInternalAsync(chatId);
        }

        public async Task<bool> AddMemberAsync(int chatId, int requesterId, string targetUsername)
        {
            // Check if requester has permission (Admin or Creator)
            var requesterRole = await GetUserRoleInChatAsync(chatId, requesterId);
            if (requesterRole == null || requesterRole == ChatRole.Member)
                return false;

            // Find target user
            var targetUser = await _context.Users.FirstOrDefaultAsync(u => u.Username == targetUsername);
            if (targetUser == null)
                return false;

            // Check if user is already in the chat
            if (await IsUserInChatInternalAsync(chatId, targetUser.Id))
                return false;

            // Add user to chat
            var userChat = new UserChat
            {
                UserId = targetUser.Id,
                ChatId = chatId,
                JoinedAt = DateTime.UtcNow,
                Role = ChatRole.Member
            };

            _context.UserChats.Add(userChat);
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> RemoveMemberAsync(int chatId, int requesterId, string targetUsername)
        {
            var requesterRole = await GetUserRoleInChatAsync(chatId, requesterId);
            if (requesterRole == null)
                return false;

            var targetUser = await _context.Users.FirstOrDefaultAsync(u => u.Username == targetUsername);
            if (targetUser == null)
                return false;

            var targetUserChat = await _context.UserChats
                .FirstOrDefaultAsync(uc => uc.ChatId == chatId && uc.UserId == targetUser.Id);

            if (targetUserChat == null)
                return false;

            // Cannot remove the creator
            if (targetUserChat.Role == ChatRole.Creator)
                return false;

            // Only Creator can remove Admins
            if (targetUserChat.Role == ChatRole.Admin && requesterRole != ChatRole.Creator)
                return false;

            // Admins can remove Members
            if (targetUserChat.Role == ChatRole.Member && requesterRole == ChatRole.Member)
                return false;

            _context.UserChats.Remove(targetUserChat);
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> PromoteToAdminAsync(int chatId, int requesterId, string targetUsername)
        {
            // Only Creator can promote to Admin
            var requesterRole = await GetUserRoleInChatAsync(chatId, requesterId);
            if (requesterRole != ChatRole.Creator)
                return false;

            var targetUser = await _context.Users.FirstOrDefaultAsync(u => u.Username == targetUsername);
            if (targetUser == null)
                return false;

            var targetUserChat = await _context.UserChats
                .FirstOrDefaultAsync(uc => uc.ChatId == chatId && uc.UserId == targetUser.Id);

            if (targetUserChat == null || targetUserChat.Role != ChatRole.Member)
                return false;

            targetUserChat.Role = ChatRole.Admin;
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> DemoteFromAdminAsync(int chatId, int requesterId, string targetUsername)
        {
            // Only Creator can demote Admin
            var requesterRole = await GetUserRoleInChatAsync(chatId, requesterId);
            if (requesterRole != ChatRole.Creator)
                return false;

            var targetUser = await _context.Users.FirstOrDefaultAsync(u => u.Username == targetUsername);
            if (targetUser == null)
                return false;

            var targetUserChat = await _context.UserChats
                .FirstOrDefaultAsync(uc => uc.ChatId == chatId && uc.UserId == targetUser.Id);

            if (targetUserChat == null || targetUserChat.Role != ChatRole.Admin)
                return false;

            targetUserChat.Role = ChatRole.Member;
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> UpdateGroupNameAsync(int chatId, int requesterId, string newName)
        {
            if (string.IsNullOrWhiteSpace(newName))
                return false;

            // Only Admin or Creator can update group name
            var requesterRole = await GetUserRoleInChatAsync(chatId, requesterId);
            if (requesterRole == null || requesterRole == ChatRole.Member)
                return false;

            var chat = await _context.Chats.FirstOrDefaultAsync(c => c.Id == chatId && c.Type == ChatType.Group);
            if (chat == null)
                return false;

            chat.Name = newName;
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<ChatRole?> GetUserRoleInChatAsync(int chatId, int userId)
        {
            var userChat = await _context.UserChats
                .FirstOrDefaultAsync(uc => uc.ChatId == chatId && uc.UserId == userId);

            return userChat?.Role;
        }

        public async Task<bool> LeaveGroupAsync(int chatId, int userId)
        {
            var userChat = await _context.UserChats
                .FirstOrDefaultAsync(uc => uc.ChatId == chatId && uc.UserId == userId);

            if (userChat == null)
                return false;

            // Creator cannot leave their own group (must transfer ownership or delete group)
            if (userChat.Role == ChatRole.Creator)
                return false;

            _context.UserChats.Remove(userChat);
            await _context.SaveChangesAsync();
            return true;
        }

        private async Task<GroupChatDto> GetGroupChatInternalAsync(int chatId)
        {
            var chat = await _context.Chats
                .Include(c => c.UserChats)
                    .ThenInclude(uc => uc.User)
                .FirstOrDefaultAsync(c => c.Id == chatId);

            if (chat == null)
                throw new InvalidOperationException("Chat not found");

            var members = chat.UserChats.Select(uc => new ChatMemberDto
            {
                UserId = uc.User.Id,
                Username = uc.User.Username!,
                IsOnline = uc.User.IsOnline,
                LastSeen = uc.User.LastSeen,
                Role = (int)uc.Role,
                JoinedAt = uc.JoinedAt
            }).ToList();

            var lastMessage = await _context.Messages
                .Where(m => m.ChatId == chatId)
                .Include(m => m.Sender)
                .OrderByDescending(m => m.SentAt)
                .FirstOrDefaultAsync();

            MessageDto? lastMessageDto = null;
            if (lastMessage != null)
            {
                lastMessageDto = new MessageDto
                {
                    Id = lastMessage.Id,
                    ChatId = lastMessage.ChatId,
                    Sender = new UserDto
                    {
                        Id = lastMessage.Sender.Id,
                        Username = lastMessage.Sender.Username!,
                        IsOnline = lastMessage.Sender.IsOnline,
                        LastSeen = lastMessage.Sender.LastSeen
                    },
                    Content = lastMessage.Content,
                    MessageType = (int)lastMessage.MessageType,
                    FileUrl = lastMessage.FileUrl,
                    FileName = lastMessage.FileName,
                    FileSize = lastMessage.FileSize,
                    SentAt = lastMessage.SentAt,
                    Status = (int)lastMessage.Status
                };
            }

            return new GroupChatDto
            {
                Id = chat.Id,
                Name = chat.Name ?? "Unnamed Group",
                CreatedAt = chat.CreatedAt,
                IsActive = chat.IsActive,
                Members = members,
                LastMessage = lastMessageDto,
                MemberCount = members.Count
            };
        }

        public async Task<bool> DeleteChatAsync(int chatId, int userId)
        {
            var chat = await _context.Chats
                .Include(c => c.UserChats)
                .Include(c => c.Messages)
                .FirstOrDefaultAsync(c => c.Id == chatId);

            if (chat == null)
                return false;

            // Check if user is a member of the chat
            var userChat = chat.UserChats.FirstOrDefault(uc => uc.UserId == userId);
            if (userChat == null)
                return false;

            // For group chats, only creator can delete
            if (chat.Type == ChatType.Group)
            {
                if (userChat.Role != ChatRole.Creator)
                    return false;
            }
            // For one-to-one chats, any member can delete (which removes them from the chat)
            else if (chat.Type == ChatType.OneToOne)
            {
                // Remove the user from the chat
                _context.UserChats.Remove(userChat);
                await _context.SaveChangesAsync();
                return true;
            }

            // For group chats, delete the entire chat
            // Remove all messages and their files
            foreach (var message in chat.Messages)
            {
                if (!string.IsNullOrEmpty(message.FileUrl))
                {
                    // Note: File deletion would be handled by FileService, but we don't have access to it here
                    // In a real implementation, you'd inject IFileService and call DeleteFileAsync
                }
            }

            _context.Messages.RemoveRange(chat.Messages);
            _context.UserChats.RemoveRange(chat.UserChats);
            _context.Chats.Remove(chat);
            await _context.SaveChangesAsync();

            return true;
        }
    }
}