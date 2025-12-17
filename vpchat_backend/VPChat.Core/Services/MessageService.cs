using Microsoft.EntityFrameworkCore;
using VPChat.Core.Models;
using VPChat.Core;
using VPChat.Shared.DTOs;

namespace VPChat.Core.Services
{
    public class MessageService : IMessageService
    {
        private readonly VPChatDbContext _context;
        private readonly IChatService _chatService;
        private readonly IFileService _fileService;

        public MessageService(VPChatDbContext context, IChatService chatService, IFileService fileService)
        {
            _context = context;
            _chatService = chatService;
            _fileService = fileService;
        }

        private async Task<Message?> SendMessageInternalAsync(int chatId, int senderId, string content, MessageType messageType = MessageType.Text)
        {
            // Verify sender is in the chat
            if (!await _chatService.IsUserInChatAsync(chatId, senderId))
            {
                return null;
            }

            var message = new Message
            {
                ChatId = chatId,
                SenderId = senderId,
                Content = content,
                MessageType = messageType,
                SentAt = DateTime.UtcNow,
                Status = MessageStatus.Sent
            };

            _context.Messages.Add(message);
            await _context.SaveChangesAsync();

            // Reload the message with Sender included
            return await _context.Messages
                .Include(m => m.Sender)
                .FirstOrDefaultAsync(m => m.Id == message.Id);
        }

        public async Task<Message?> SendMediaMessageAsync(int chatId, int senderId, string fileUrl, string fileName, long fileSize, MessageType messageType)
        {
            // Verify sender is in the chat
            if (!await _chatService.IsUserInChatAsync(chatId, senderId))
            {
                return null;
            }

            var message = new Message
            {
                ChatId = chatId,
                SenderId = senderId,
                Content = null, // Media messages don't have text content
                MessageType = messageType,
                FileUrl = fileUrl,
                FileName = fileName,
                FileSize = fileSize,
                SentAt = DateTime.UtcNow,
                Status = MessageStatus.Sent
            };

            _context.Messages.Add(message);
            await _context.SaveChangesAsync();

            // Reload the message with Sender included
            return await _context.Messages
                .Include(m => m.Sender)
                .FirstOrDefaultAsync(m => m.Id == message.Id);
        }

        public async Task<IEnumerable<Message>> GetChatMessagesInternalAsync(int chatId, int userId, int page = 1, int pageSize = 20)
        {
            // Verify user is in the chat
            if (!await _chatService.IsUserInChatAsync(chatId, userId))
            {
                return Enumerable.Empty<Message>();
            }

            return await _context.Messages
                .Where(m => m.ChatId == chatId)
                .Include(m => m.Sender)
                .OrderByDescending(m => m.SentAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();
        }

        public async Task<Message?> GetMessageByIdAsync(int messageId, int userId)
        {
            var message = await _context.Messages
                .Include(m => m.Sender)
                .Include(m => m.Chat)
                .FirstOrDefaultAsync(m => m.Id == messageId);

            if (message == null || !await _chatService.IsUserInChatAsync(message.ChatId, userId))
            {
                return null;
            }

            return message;
        }

        public async Task<bool> MarkMessageAsReadInternalAsync(int messageId, int userId)
        {
            var message = await _context.Messages
                .Include(m => m.Chat)
                .FirstOrDefaultAsync(m => m.Id == messageId);

            if (message == null || !await _chatService.IsUserInChatAsync(message.ChatId, userId))
            {
                return false;
            }

            message.Status = MessageStatus.Seen;
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<int> GetUnreadMessageCountAsync(int chatId, int userId)
        {
            // Verify user is in the chat
            if (!await _chatService.IsUserInChatAsync(chatId, userId))
            {
                return 0;
            }

            return await _context.Messages
                .CountAsync(m => m.ChatId == chatId && m.Status != MessageStatus.Seen && m.SenderId != userId);
        }

        // Interface implementation methods
        public async Task<List<MessageDto>> GetChatMessagesAsync(int chatId, int userId, int page = 1, int pageSize = 50)
        {
            var messages = await GetChatMessagesInternalAsync(chatId, userId, page, pageSize);
            return messages.Select(MapToMessageDto).ToList();
        }

        public async Task<MessageDto> SendMessageAsync(int chatId, int userId, string content, int messageType = 0)
        {
            var messageTypeEnum = (MessageType)messageType;
            var message = await SendMessageInternalAsync(chatId, userId, content, messageTypeEnum);
            if (message == null)
                throw new InvalidOperationException("Failed to send message");

            return MapToMessageDto(message);
        }

        public async Task<bool> MarkMessageAsReadAsync(int messageId, int userId)
        {
            return await MarkMessageAsReadInternalAsync(messageId, userId);
        }

        private MessageDto MapToMessageDto(Message message)
        {
            return new MessageDto
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
            };
        }

        public async Task<MessageDto> SendFileMessageAsync(
            int chatId,
            int senderId,
            Stream fileStream,
            string fileName,
            string contentType,
            MessageType messageType)
        {
            // Verify sender is in the chat
            if (!await _chatService.IsUserInChatAsync(chatId, senderId))
            {
                throw new UnauthorizedAccessException("User is not a member of this chat");
            }

            // Validate file type
            if (!_fileService.IsValidFileType(contentType, messageType))
            {
                throw new InvalidOperationException($"Invalid file type: {contentType} for message type: {messageType}");
            }

            // Validate file size
            var maxSize = _fileService.GetMaxFileSize(messageType);
            if (fileStream.Length > maxSize)
            {
                throw new InvalidOperationException($"File too large. Max size: {maxSize / 1024 / 1024} MB");
            }

            // Save file
            var (fileUrl, originalFileName, fileSize) = await _fileService.SaveFileAsync(
                fileStream, 
                fileName, 
                contentType);

            // Create message
            var message = new Message
            {
                ChatId = chatId,
                SenderId = senderId,
                Content = null, // No text content for file messages
                MessageType = messageType,
                FileUrl = fileUrl,
                FileName = originalFileName,
                FileSize = fileSize,
                SentAt = DateTime.UtcNow,
                Status = MessageStatus.Sent
            };

            _context.Messages.Add(message);
            await _context.SaveChangesAsync();

            // Reload with sender info
            await _context.Entry(message).Reference(m => m.Sender).LoadAsync();

            return MapToMessageDto(message);
        }

        public async Task<Message?> GetMessageByIdAsync(int messageId)
        {
            return await _context.Messages
                .Include(m => m.Sender)
                .Include(m => m.Chat)
                .FirstOrDefaultAsync(m => m.Id == messageId);
        }

        public async Task<bool> DeleteMessageAsync(int messageId, int userId)
        {
            var message = await _context.Messages
                .Include(m => m.Chat)
                .FirstOrDefaultAsync(m => m.Id == messageId);

            if (message == null)
                return false;

            // Only allow sender to delete their own messages
            if (message.SenderId != userId)
                return false;

            // If it's a file message, delete the file as well
            if (!string.IsNullOrEmpty(message.FileUrl))
            {
                await _fileService.DeleteFileAsync(message.FileUrl);
            }

            _context.Messages.Remove(message);
            await _context.SaveChangesAsync();

            return true;
        }

        public async Task<bool> MarkMessagesAsDeliveredAsync(int chatId, int userId)
        {
            // Verify user is in the chat
            if (!await _chatService.IsUserInChatAsync(chatId, userId))
                return false;

            // Update all messages in the chat that are sent by others and not yet delivered/seen
            var messagesToUpdate = await _context.Messages
                .Where(m => m.ChatId == chatId && m.SenderId != userId && m.Status == MessageStatus.Sent)
                .ToListAsync();

            foreach (var message in messagesToUpdate)
            {
                message.Status = MessageStatus.Delivered;
            }

            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> MarkMessageAsSeenAsync(int messageId, int userId)
        {
            var message = await _context.Messages
                .Include(m => m.Chat)
                .FirstOrDefaultAsync(m => m.Id == messageId);

            if (message == null)
                return false;

            // Verify user is in the chat and is not the sender
            if (!await _chatService.IsUserInChatAsync(message.ChatId, userId) || message.SenderId == userId)
                return false;

            // Update status to seen
            message.Status = MessageStatus.Seen;
            await _context.SaveChangesAsync();

            return true;
        }
    }
}