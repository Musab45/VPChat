using Microsoft.AspNetCore.Mvc;
using VPChat.Core.Services;
using VPChat.Shared.DTOs;

namespace VPChat.Server.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly IUserService _userService;

        public AuthController(IUserService userService)
        {
            _userService = userService;
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Username) || string.IsNullOrWhiteSpace(request.Password))
                return BadRequest("Username and password are required.");

            var user = await _userService.RegisterAsync(request.Username, request.Password);
            if (user == null)
                return BadRequest("Username already exists.");

            return Ok(new UserDto
            {
                Id = user.Id,
                Username = user.Username!,
                IsOnline = user.IsOnline,
                LastSeen = user.LastSeen
            });
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            var token = await _userService.LoginAsync(request.Username, request.Password);
            if (token == null)
                return Unauthorized("Invalid username or password.");

            var user = await _userService.GetUserByUsernameAsync(request.Username);
            if (user == null)
                return Unauthorized();

            // Debug: Log token information
            Console.WriteLine($"Generated token length: {token.Length}");
            Console.WriteLine($"Token structure check - Parts: {token.Split('.').Length} (should be 3)");

            return Ok(new AuthResponse
            {
                Token = token,
                User = new UserDto
                {
                    Id = user.Id,
                    Username = user.Username!,
                    IsOnline = user.IsOnline,
                    LastSeen = user.LastSeen
                }
            });
        }
    }
}