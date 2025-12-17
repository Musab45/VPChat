using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using VPChat.Core.Services;
using VPChat.Shared.DTOs;

namespace VPChat.Server.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class ChatController : ControllerBase
    {
        private readonly IChatService _chatService;

        public ChatController(IChatService chatService)
        {
            _chatService = chatService;
        }

        [HttpGet("my-chats")]
        public async Task<IActionResult> GetMyChats()
        {
            try
            {
                var userId = GetCurrentUserId();
                var chats = await _chatService.GetUserChatsAsync(userId);
                return Ok(chats);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("create-one-to-one")]
        public async Task<IActionResult> CreateOneToOneChat([FromBody] CreateChatRequest request)
        {
            try
            {
                var userId = GetCurrentUserId();
                var chat = await _chatService.CreateOneToOneChatAsync(userId, request.TargetUsername);
                return Ok(chat);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpGet("{chatId}")]
        public async Task<IActionResult> GetChat(int chatId)
        {
            try
            {
                var userId = GetCurrentUserId();
                var chat = await _chatService.GetChatAsync(chatId, userId);
                if (chat == null)
                    return NotFound(new { message = "Chat not found or access denied" });

                return Ok(chat);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        // ============= GROUP CHAT ENDPOINTS =============

        [HttpPost("group/create")]
        public async Task<IActionResult> CreateGroupChat([FromBody] CreateGroupChatRequest request)
        {
            try
            {
                var userId = GetCurrentUserId();
                var groupChat = await _chatService.CreateGroupChatAsync(userId, request.GroupName, request.MemberUsernames);
                return Ok(groupChat);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpGet("group/{chatId}")]
        public async Task<IActionResult> GetGroupChat(int chatId)
        {
            try
            {
                var userId = GetCurrentUserId();
                var groupChat = await _chatService.GetGroupChatAsync(chatId, userId);
                if (groupChat == null)
                    return NotFound(new { message = "Group chat not found or access denied" });

                return Ok(groupChat);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("group/{chatId}/add-member")]
        public async Task<IActionResult> AddMember(int chatId, [FromBody] AddMemberRequest request)
        {
            try
            {
                var userId = GetCurrentUserId();
                var success = await _chatService.AddMemberAsync(chatId, userId, request.Username);
                
                if (!success)
                    return BadRequest(new { message = "Failed to add member. You may not have permission or the user is already in the group." });

                return Ok(new { message = "Member added successfully" });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpDelete("group/{chatId}/remove-member")]
        public async Task<IActionResult> RemoveMember(int chatId, [FromBody] AddMemberRequest request)
        {
            try
            {
                var userId = GetCurrentUserId();
                var success = await _chatService.RemoveMemberAsync(chatId, userId, request.Username);
                
                if (!success)
                    return BadRequest(new { message = "Failed to remove member. You may not have permission or the user is not in the group." });

                return Ok(new { message = "Member removed successfully" });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPut("group/{chatId}/promote-admin")]
        public async Task<IActionResult> PromoteToAdmin(int chatId, [FromBody] UpdateMemberRoleRequest request)
        {
            try
            {
                var userId = GetCurrentUserId();
                var success = await _chatService.PromoteToAdminAsync(chatId, userId, request.Username);
                
                if (!success)
                    return BadRequest(new { message = "Failed to promote member. Only the creator can promote members to admin." });

                return Ok(new { message = "Member promoted to admin successfully" });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPut("group/{chatId}/demote-admin")]
        public async Task<IActionResult> DemoteFromAdmin(int chatId, [FromBody] UpdateMemberRoleRequest request)
        {
            try
            {
                var userId = GetCurrentUserId();
                var success = await _chatService.DemoteFromAdminAsync(chatId, userId, request.Username);
                
                if (!success)
                    return BadRequest(new { message = "Failed to demote admin. Only the creator can demote admins." });

                return Ok(new { message = "Admin demoted to member successfully" });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPut("group/{chatId}/update-name")]
        public async Task<IActionResult> UpdateGroupName(int chatId, [FromBody] UpdateGroupInfoRequest request)
        {
            try
            {
                var userId = GetCurrentUserId();
                var success = await _chatService.UpdateGroupNameAsync(chatId, userId, request.GroupName);
                
                if (!success)
                    return BadRequest(new { message = "Failed to update group name. Only admins and creator can update group name." });

                return Ok(new { message = "Group name updated successfully" });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("group/{chatId}/leave")]
        public async Task<IActionResult> LeaveGroup(int chatId)
        {
            try
            {
                var userId = GetCurrentUserId();
                var success = await _chatService.LeaveGroupAsync(chatId, userId);
                
                if (!success)
                    return BadRequest(new { message = "Failed to leave group. Creators cannot leave their own group." });

                return Ok(new { message = "Left group successfully" });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpDelete("{chatId}")]
        public async Task<IActionResult> DeleteChat(int chatId)
        {
            try
            {
                var userId = GetCurrentUserId();
                var success = await _chatService.DeleteChatAsync(chatId, userId);
                
                if (!success)
                    return BadRequest(new { message = "Failed to delete chat. You may not have permission or the chat may not exist." });

                return Ok(new { message = "Chat deleted successfully" });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpGet("group/{chatId}/my-role")]
        public async Task<IActionResult> GetMyRole(int chatId)
        {
            try
            {
                var userId = GetCurrentUserId();
                var role = await _chatService.GetUserRoleInChatAsync(chatId, userId);
                
                if (role == null)
                    return NotFound(new { message = "You are not a member of this group" });

                return Ok(new { role = (int)role, roleName = role.ToString() });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
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
    }
}