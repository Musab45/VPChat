using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using System.Security.Claims;
using VPChat.Core.Services;
using VPChat.Server.Hubs;
using VPChat.Shared.DTOs;

namespace VPChat.Server.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class MessageController : ControllerBase
    {
        private readonly IMessageService _messageService;
        private readonly IHubContext<ChatHub> _hubContext;

        public MessageController(IMessageService messageService, IHubContext<ChatHub> hubContext)
        {
            _messageService = messageService;
            _hubContext = hubContext;
        }

        [HttpGet("chat/{chatId}")]
        public async Task<IActionResult> GetChatMessages(int chatId, [FromQuery] int page = 1, [FromQuery] int pageSize = 50)
        {
            try
            {
                var userId = GetCurrentUserId();
                var messages = await _messageService.GetChatMessagesAsync(chatId, userId, page, pageSize);
                return Ok(messages);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("chat/{chatId}/send")]
        public async Task<IActionResult> SendMessage(int chatId, [FromBody] SendMessageRequest request)
        {
            try
            {
                var userId = GetCurrentUserId();
                var message = await _messageService.SendMessageAsync(chatId, userId, request.Content, request.MessageType);
                
                // Broadcast message to all connected clients in the chat via SignalR
                var groupName = $"chat_{chatId}";
                await _hubContext.Clients.Group(groupName).SendAsync("ReceiveMessage", message);
                
                return Ok(message);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPut("{messageId}/mark-read")]
        public async Task<IActionResult> MarkMessageAsRead(int messageId)
        {
            try
            {
                var userId = GetCurrentUserId();
                var success = await _messageService.MarkMessageAsReadAsync(messageId, userId);
                if (!success)
                    return NotFound(new { message = "Message not found or access denied" });

                return Ok(new { message = "Message marked as read" });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("chat/{chatId}/upload")]
        [Consumes("multipart/form-data")]
        [DisableRequestSizeLimit]
        public async Task<IActionResult> UploadFile(int chatId)
        {
            try
            {
                var userId = GetCurrentUserId();
                
                // Get file and messageType from form
                var file = Request.Form.Files.GetFile("file");
                var messageTypeStr = Request.Form["messageType"].ToString();

                // Validate file
                if (file == null || file.Length == 0)
                {
                    return BadRequest(new { message = "No file uploaded" });
                }

                if (!int.TryParse(messageTypeStr, out int messageType))
                {
                    return BadRequest(new { message = "Invalid message type" });
                }

                var msgType = (VPChat.Core.Models.MessageType)messageType;

                // Upload file and create message
                using (var stream = file.OpenReadStream())
                {
                    var message = await _messageService.SendFileMessageAsync(
                        chatId,
                        userId,
                        stream,
                        file.FileName,
                        file.ContentType,
                        msgType);

                    // Broadcast via SignalR
                    await _hubContext.Clients.Group($"chat_{chatId}")
                        .SendAsync("ReceiveMessage", message);

                    return Ok(message);
                }
            }
            catch (UnauthorizedAccessException ex)
            {
                return Unauthorized(new { message = ex.Message });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error uploading file", error = ex.Message });
            }
        }

        [HttpGet("file/{messageId}")]
        public async Task<IActionResult> GetFile(int messageId)
        {
            try
            {
                var message = await _messageService.GetMessageByIdAsync(messageId);
                
                if (message == null || string.IsNullOrEmpty(message.FileUrl))
                {
                    return NotFound(new { message = "File not found" });
                }

                // Return file URL (client can download from the URL)
                return Ok(new { 
                    fileUrl = message.FileUrl,
                    fileName = message.FileName,
                    fileSize = message.FileSize,
                    messageType = message.MessageType
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error retrieving file", error = ex.Message });
            }
        }

        private int GetCurrentUserId()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out var userId))
            {
                throw new UnauthorizedAccessException("Invalid user token");
            }
            return userId;
        }

        [HttpDelete("{messageId}")]
        public async Task<IActionResult> DeleteMessage(int messageId)
        {
            try
            {
                var userId = GetCurrentUserId();
                var success = await _messageService.DeleteMessageAsync(messageId, userId);
                
                if (!success)
                    return NotFound(new { message = "Message not found or access denied" });

                return Ok(new { message = "Message deleted successfully" });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("chat/{chatId}/delivered")]
        public async Task<IActionResult> MarkMessagesAsDelivered(int chatId)
        {
            try
            {
                var userId = GetCurrentUserId();
                var success = await _messageService.MarkMessagesAsDeliveredAsync(chatId, userId);
                
                if (!success)
                    return BadRequest(new { message = "Failed to mark messages as delivered" });

                // Broadcast status update to all chat members
                var groupName = $"chat_{chatId}";
                var messageIds = await _messageService.GetChatMessagesAsync(chatId, userId, 1, 1000); // Get recent messages
                var deliveredMessageIds = messageIds
                    .Where(m => m.Status == 1) // Delivered status
                    .Select(m => m.Id)
                    .ToList();

                if (deliveredMessageIds.Any())
                {
                    await _hubContext.Clients.Group(groupName).SendAsync("MessageStatusUpdate", new
                    {
                        chatId,
                        messageIds = deliveredMessageIds,
                        status = 1 // Delivered
                    });
                }

                return Ok(new { message = "Messages marked as delivered" });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPut("{messageId}/seen")]
        public async Task<IActionResult> MarkMessageAsSeen(int messageId)
        {
            try
            {
                var userId = GetCurrentUserId();
                var success = await _messageService.MarkMessageAsSeenAsync(messageId, userId);
                
                if (!success)
                    return NotFound(new { message = "Message not found or access denied" });

                // Broadcast status update to all chat members
                var message = await _messageService.GetMessageByIdAsync(messageId);
                if (message != null)
                {
                    var groupName = $"chat_{message.ChatId}";
                    await _hubContext.Clients.Group(groupName).SendAsync("MessageStatusUpdate", new
                    {
                        chatId = message.ChatId,
                        messageIds = new List<int> { messageId },
                        status = 2 // Seen
                    });
                }

                return Ok(new { message = "Message marked as seen" });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }
    }
}