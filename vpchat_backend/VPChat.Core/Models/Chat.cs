namespace VPChat.Core.Models;

public enum ChatType
{
    OneToOne,
    Group
}

public class Chat
{
    public int Id { get; set; }
    public ChatType Type { get; set; }
    public string? Name { get; set; } // For group chats
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public bool IsActive { get; set; } = true;

    // Navigation properties
    public ICollection<UserChat> UserChats { get; set; } = new List<UserChat>();
    public ICollection<Message> Messages { get; set; } = new List<Message>();
}