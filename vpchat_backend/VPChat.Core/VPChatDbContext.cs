using Microsoft.EntityFrameworkCore;
using VPChat.Core.Models;

namespace VPChat.Core
{
    public class VPChatDbContext : DbContext
    {
        public VPChatDbContext(DbContextOptions<VPChatDbContext> options) : base(options) { }

        public DbSet<User> Users { get; set; }
        public DbSet<Chat> Chats { get; set; }
        public DbSet<Message> Messages { get; set; }
        public DbSet<UserChat> UserChats { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Configure UserChat composite key
            modelBuilder.Entity<UserChat>()
                .HasKey(uc => new { uc.UserId, uc.ChatId });

            // Configure relationships
            modelBuilder.Entity<UserChat>()
                .HasOne(uc => uc.User)
                .WithMany(u => u.UserChats)
                .HasForeignKey(uc => uc.UserId);

            modelBuilder.Entity<UserChat>()
                .HasOne(uc => uc.Chat)
                .WithMany(c => c.UserChats)
                .HasForeignKey(uc => uc.ChatId);

            modelBuilder.Entity<Message>()
                .HasOne(m => m.Chat)
                .WithMany(c => c.Messages)
                .HasForeignKey(m => m.ChatId);

            modelBuilder.Entity<Message>()
                .HasOne(m => m.Sender)
                .WithMany(u => u.Messages)
                .HasForeignKey(m => m.SenderId);

            // Add indexes for performance
            modelBuilder.Entity<Message>()
                .HasIndex(m => m.ChatId);

            modelBuilder.Entity<Message>()
                .HasIndex(m => new { m.ChatId, m.SentAt });

            modelBuilder.Entity<UserChat>()
                .HasIndex(uc => uc.UserId);

            // For 1-to-1 chats, ensure unique participant combinations
            modelBuilder.Entity<Chat>()
                .HasIndex(c => c.Type);
        }
    }
}