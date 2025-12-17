namespace VPChat.Core.Models;

public enum ChatRole
{
    Member = 0,      // Regular member with no special permissions
    Admin = 1,       // Can add/remove members, manage chat settings
    Creator = 2      // SuperAdmin - created the group, can promote/demote admins, cannot be removed
}

public class UserChat
{
    public int UserId { get; set; }
    public int ChatId { get; set; }
    public DateTime JoinedAt { get; set; } = DateTime.UtcNow;
    public ChatRole Role { get; set; } = ChatRole.Member;

    // Navigation properties
    public User User { get; set; } = null!;
    public Chat Chat { get; set; } = null!;
}