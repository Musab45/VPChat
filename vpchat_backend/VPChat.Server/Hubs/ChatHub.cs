using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using System.Security.Claims;
using VPChat.Core.Services;
using VPChat.Shared.DTOs;

namespace VPChat.Server.Hubs
{
    [Authorize]
    public class ChatHub : Hub
    {
        private readonly IMessageService _messageService;
        private readonly IChatService _chatService;
        private readonly IConnectionManager _connectionManager;
        private readonly IUserService _userService;

        public ChatHub(
            IMessageService messageService, 
            IChatService chatService,
            IConnectionManager connectionManager,
            IUserService userService)
        {
            _messageService = messageService;
            _chatService = chatService;
            _connectionManager = connectionManager;
            _userService = userService;
        }

        public override async Task OnConnectedAsync()
        {
            var userId = GetCurrentUserId();
            var connectionId = Context.ConnectionId;

            if (userId.HasValue)
            {
                // Add connection to manager
                _connectionManager.AddConnection(userId.Value, connectionId);

                // Update user status to online
                var user = await _userService.GetUserByIdAsync(userId.Value);
                if (user != null)
                {
                    user.IsOnline = true;
                    user.LastSeen = DateTime.UtcNow;
                    await _userService.UpdateUserStatusAsync(user.Id, true);
                }

                Console.WriteLine($"[ChatHub] User {userId} connected. ConnectionId: {connectionId}");
            }

            await base.OnConnectedAsync();
        }

        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            var userId = GetCurrentUserId();
            var connectionId = Context.ConnectionId;

            if (userId.HasValue)
            {
                // Remove connection
                _connectionManager.RemoveConnection(connectionId);

                // If user has no more connections, mark as offline
                if (!_connectionManager.IsUserOnline(userId.Value))
                {
                    var user = await _userService.GetUserByIdAsync(userId.Value);
                    if (user != null)
                    {
                        user.IsOnline = false;
                        user.LastSeen = DateTime.UtcNow;
                        await _userService.UpdateUserStatusAsync(user.Id, false);
                    }
                }

                Console.WriteLine($"[ChatHub] User {userId} disconnected. ConnectionId: {connectionId}");
            }

            await base.OnDisconnectedAsync(exception);
        }

        /// <summary>
        /// Join a chat room to start receiving messages
        /// </summary>
        public async Task JoinChat(int chatId)
        {
            var userId = GetCurrentUserId();
            if (!userId.HasValue)
            {
                throw new HubException("User not authenticated");
            }

            // Verify user is a member of this chat
            var isMember = await _chatService.IsUserInChatAsync(chatId, userId.Value);
            if (!isMember)
            {
                throw new HubException("You are not a member of this chat");
            }

            // Add user to SignalR group for this chat
            var groupName = GetChatGroupName(chatId);
            await Groups.AddToGroupAsync(Context.ConnectionId, groupName);

            Console.WriteLine($"[ChatHub] User {userId} joined chat {chatId} (Group: {groupName})");

            // Notify other users in the chat
            await Clients.OthersInGroup(groupName).SendAsync("UserJoined", new
            {
                UserId = userId.Value,
                ChatId = chatId,
                Timestamp = DateTime.UtcNow
            });
        }

        /// <summary>
        /// Leave a chat room
        /// </summary>
        public async Task LeaveChat(int chatId)
        {
            var userId = GetCurrentUserId();
            if (!userId.HasValue)
            {
                throw new HubException("User not authenticated");
            }

            var groupName = GetChatGroupName(chatId);
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, groupName);

            Console.WriteLine($"[ChatHub] User {userId} left chat {chatId}");

            // Notify other users
            await Clients.OthersInGroup(groupName).SendAsync("UserLeft", new
            {
                UserId = userId.Value,
                ChatId = chatId,
                Timestamp = DateTime.UtcNow
            });
        }

        /// <summary>
        /// Send a message in real-time
        /// </summary>
        public async Task SendMessage(int chatId, string content, int messageType = 0)
        {
            var userId = GetCurrentUserId();
            if (!userId.HasValue)
            {
                throw new HubException("User not authenticated");
            }

            try
            {
                // Verify user is in the chat
                var isMember = await _chatService.IsUserInChatAsync(chatId, userId.Value);
                if (!isMember)
                {
                    throw new HubException("You are not a member of this chat");
                }

                // Save message to database
                var messageDto = await _messageService.SendMessageAsync(chatId, userId.Value, content, messageType);

                // Broadcast message to all users in the chat (including sender for confirmation)
                var groupName = GetChatGroupName(chatId);
                await Clients.Group(groupName).SendAsync("ReceiveMessage", messageDto);

                Console.WriteLine($"[ChatHub] Message sent by user {userId} in chat {chatId}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[ChatHub] Error sending message: {ex.Message}");
                throw new HubException($"Failed to send message: {ex.Message}");
            }
        }

        /// <summary>
        /// Notify that user is typing
        /// </summary>
        public async Task SendTypingIndicator(int chatId, bool isTyping)
        {
            var userId = GetCurrentUserId();
            if (!userId.HasValue) return;

            var groupName = GetChatGroupName(chatId);
            
            // Send to others in the group (not to sender)
            await Clients.OthersInGroup(groupName).SendAsync("UserTyping", new
            {
                UserId = userId.Value,
                ChatId = chatId,
                IsTyping = isTyping,
                Timestamp = DateTime.UtcNow
            });
        }

        /// <summary>
        /// Mark message as read in real-time
        /// </summary>
        public async Task MarkMessageAsRead(int messageId, int chatId)
        {
            var userId = GetCurrentUserId();
            if (!userId.HasValue) return;

            try
            {
                var success = await _messageService.MarkMessageAsReadAsync(messageId, userId.Value);
                if (success)
                {
                    var groupName = GetChatGroupName(chatId);
                    
                    // Notify others that message was read
                    await Clients.OthersInGroup(groupName).SendAsync("MessageRead", new
                    {
                        MessageId = messageId,
                        ReadBy = userId.Value,
                        ChatId = chatId,
                        Timestamp = DateTime.UtcNow
                    });
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[ChatHub] Error marking message as read: {ex.Message}");
            }
        }

        /// <summary>
        /// Send a file message (image, audio, video, or document) via SignalR
        /// Note: This is for notification purposes. Actual file upload happens via REST API.
        /// </summary>
        public async Task NotifyFileMessage(int chatId, int messageId)
        {
            var userId = GetCurrentUserId();
            if (!userId.HasValue)
            {
                throw new HubException("User not authenticated");
            }

            try
            {
                // Get the message details
                var message = await _messageService.GetMessageByIdAsync(messageId);
                if (message == null)
                {
                    throw new HubException("Message not found");
                }

                // Verify user is in the chat
                var isMember = await _chatService.IsUserInChatAsync(chatId, userId.Value);
                if (!isMember)
                {
                    throw new HubException("You are not a member of this chat");
                }

                // Broadcast to all users in the chat
                var groupName = GetChatGroupName(chatId);
                await Clients.Group(groupName).SendAsync("ReceiveMessage", new MessageDto
                {
                    Id = message.Id,
                    ChatId = message.ChatId,
                    Sender = new UserDto
                    {
                        Id = message.Sender.Id,
                        Username = message.Sender.Username!,
                        IsOnline = message.Sender.IsOnline,
                        LastSeen = message.Sender.LastSeen
                    },
                    Content = message.Content,
                    MessageType = (int)message.MessageType,
                    FileUrl = message.FileUrl,
                    FileName = message.FileName,
                    FileSize = message.FileSize,
                    SentAt = message.SentAt,
                    Status = (int)message.Status
                });

                Console.WriteLine($"[ChatHub] File message {messageId} notified in chat {chatId}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[ChatHub] Error notifying file message: {ex.Message}");
                throw new HubException($"Failed to notify file message: {ex.Message}");
            }
        }

        // Helper methods
        private int? GetCurrentUserId()
        {
            var userIdClaim = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out var userId))
            {
                return null;
            }
            return userId;
        }

        private static string GetChatGroupName(int chatId)
        {
            return $"chat_{chatId}";
        }
    }
}
