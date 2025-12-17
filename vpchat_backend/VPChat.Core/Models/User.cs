namespace VPChat.Core.Models;

public class User
{
    public int Id { get; set; }
    public string? Username { get; set; }
    public string? PasswordHash { get; set; }
    public DateTime? LastSeen { get; set; } // can be null, agar off ho
    public bool IsOnline { get; set; }

    // Navigation properties
    public ICollection<UserChat> UserChats { get; set; } = new List<UserChat>();
    public ICollection<Message> Messages { get; set; } = new List<Message>();
}