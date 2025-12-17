namespace VPChat.Core.Services
{
    public interface IConnectionManager
    {
        void AddConnection(int userId, string connectionId);
        void RemoveConnection(string connectionId);
        List<string> GetUserConnections(int userId);
        int? GetUserIdByConnection(string connectionId);
        bool IsUserOnline(int userId);
        void UpdateLastSeen(int userId);
    }
}
