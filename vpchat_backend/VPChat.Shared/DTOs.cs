namespace VPChat.Shared.DTOs
{
    public class RegisterRequest
    {
        public string Username { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }

    public class LoginRequest
    {
        public string Username { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }

    public class AuthResponse
    {
        public string Token { get; set; } = string.Empty;
        public UserDto User { get; set; } = new();
    }

    public class UserDto
    {
        public int Id { get; set; }
        public string Username { get; set; } = string.Empty;
        public bool IsOnline { get; set; }
        public DateTime? LastSeen { get; set; }
    }

    public class CreateChatRequest
    {
        public string TargetUsername { get; set; } = string.Empty;
    }

    public class ChatDto
    {
        public int Id { get; set; }
        public int Type { get; set; }
        public string? Name { get; set; }
        public DateTime CreatedAt { get; set; }
        public bool IsActive { get; set; }
        public List<UserDto> Participants { get; set; } = new();
        public MessageDto? LastMessage { get; set; }
    }

    public class SendMessageRequest
    {
        public string Content { get; set; } = string.Empty;
        public int MessageType { get; set; } = 0; // 0 = Text
    }

    public class MessageDto
    {
        public int Id { get; set; }
        public int ChatId { get; set; }
        public UserDto Sender { get; set; } = new();
        public string? Content { get; set; }
        public int MessageType { get; set; }
        public string? FileUrl { get; set; }
        public string? FileName { get; set; }
        public long? FileSize { get; set; }
        public DateTime SentAt { get; set; }
        public int Status { get; set; } // 0 = Sent, 1 = Delivered, 2 = Seen
    }

    // Group Chat DTOs
    public class CreateGroupChatRequest
    {
        public string GroupName { get; set; } = string.Empty;
        public List<string> MemberUsernames { get; set; } = new(); // Initial members (optional)
    }

    public class AddMemberRequest
    {
        public string Username { get; set; } = string.Empty;
    }

    public class UpdateMemberRoleRequest
    {
        public string Username { get; set; } = string.Empty;
        public int Role { get; set; } // 0 = Member, 1 = Admin
    }

    public class UpdateGroupInfoRequest
    {
        public string GroupName { get; set; } = string.Empty;
    }

    public class ChatMemberDto
    {
        public int UserId { get; set; }
        public string Username { get; set; } = string.Empty;
        public bool IsOnline { get; set; }
        public DateTime? LastSeen { get; set; }
        public int Role { get; set; } // 0 = Member, 1 = Admin, 2 = Creator
        public DateTime JoinedAt { get; set; }
    }

    public class GroupChatDto
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public bool IsActive { get; set; }
        public List<ChatMemberDto> Members { get; set; } = new();
        public MessageDto? LastMessage { get; set; }
        public int MemberCount { get; set; }
    }
}