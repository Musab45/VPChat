using VPChat.Core.Models;
using VPChat.Shared.DTOs;

namespace VPChat.Core.Services
{
    public interface IMessageService
    {
        Task<List<MessageDto>> GetChatMessagesAsync(int chatId, int userId, int page = 1, int pageSize = 50);
        Task<MessageDto> SendMessageAsync(int chatId, int userId, string content, int messageType = 0);
        Task<bool> MarkMessageAsReadAsync(int messageId, int userId);
        
        /// <summary>
        /// Sends a file message (image, audio, video, or document)
        /// </summary>
        Task<MessageDto> SendFileMessageAsync(
            int chatId, 
            int senderId, 
            Stream fileStream, 
            string fileName, 
            string contentType, 
            MessageType messageType);
        
        /// <summary>
        /// Gets a message by ID for file download
        /// </summary>
        Task<Message?> GetMessageByIdAsync(int messageId);
        
        /// <summary>
        /// Deletes a message if the user is the sender
        /// </summary>
        Task<bool> DeleteMessageAsync(int messageId, int userId);
        
        /// <summary>
        /// Marks messages as delivered for a specific chat and user
        /// </summary>
        Task<bool> MarkMessagesAsDeliveredAsync(int chatId, int userId);
        
        /// <summary>
        /// Marks a specific message as seen/read by a user
        /// </summary>
        Task<bool> MarkMessageAsSeenAsync(int messageId, int userId);
    }
}