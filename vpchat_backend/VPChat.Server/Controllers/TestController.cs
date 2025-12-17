using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VPChat.Core.Services;
using VPChat.Shared.DTOs;

namespace VPChat.Server.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class TestController : ControllerBase
    {
        private readonly IUserService _userService;

        public TestController(IUserService userService)
        {
            _userService = userService;
        }

        [HttpGet("me")]
        [Authorize]
        public async Task<IActionResult> GetCurrentUser()
        {
            var username = User.Identity?.Name;
            if (username == null)
                return Unauthorized(new { message = "No username found in token" });

            var user = await _userService.GetUserByUsernameAsync(username);
            if (user == null)
                return NotFound(new { message = $"User '{username}' not found" });

            return Ok(new UserDto
            {
                Id = user.Id,
                Username = user.Username!,
                IsOnline = user.IsOnline,
                LastSeen = user.LastSeen
            });
        }

        [HttpGet("auth-debug")]
        [Authorize]
        public IActionResult AuthDebug()
        {
            var claims = User.Claims.Select(c => new { c.Type, c.Value }).ToList();
            return Ok(new
            {
                IsAuthenticated = User.Identity?.IsAuthenticated,
                AuthenticationType = User.Identity?.AuthenticationType,
                Name = User.Identity?.Name,
                Claims = claims
            });
        }
    }
}