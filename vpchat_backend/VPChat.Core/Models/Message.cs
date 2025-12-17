namespace VPChat.Core.Models;

public enum MessageType
{
    Text,
    Image,
    Audio,
    Video,
    File
}

public enum MessageStatus
{
    Sent,      // Message sent by sender
    Delivered, // Message delivered to recipient(s)
    Seen       // Message seen/read by recipient(s)
}

public class Message
{
    public int Id { get; set; }
    public int ChatId { get; set; }
    public int SenderId { get; set; }
    public string? Content { get; set; } // For text messages
    public MessageType MessageType { get; set; } = MessageType.Text;
    public string? FileUrl { get; set; } // For media files
    public string? FileName { get; set; } // Original filename
    public long? FileSize { get; set; } // File size in bytes
    public DateTime SentAt { get; set; } = DateTime.UtcNow;
    public MessageStatus Status { get; set; } = MessageStatus.Sent;

    // Navigation properties
    public Chat Chat { get; set; } = null!;
    public User Sender { get; set; } = null!;
}