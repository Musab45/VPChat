using System.Collections.Concurrent;

namespace VPChat.Core.Services
{
    public class ConnectionManager : IConnectionManager
    {
        // Thread-safe dictionaries for concurrent access
        private readonly ConcurrentDictionary<string, int> _connectionToUser = new();
        private readonly ConcurrentDictionary<int, HashSet<string>> _userToConnections = new();
        private readonly object _lock = new();

        public void AddConnection(int userId, string connectionId)
        {
            lock (_lock)
            {
                // Map connectionId to userId
                _connectionToUser[connectionId] = userId;

                // Map userId to list of connectionIds (user can have multiple connections/devices)
                if (!_userToConnections.ContainsKey(userId))
                {
                    _userToConnections[userId] = new HashSet<string>();
                }
                _userToConnections[userId].Add(connectionId);

                Console.WriteLine($"[ConnectionManager] User {userId} connected with ConnectionId: {connectionId}. Total connections: {_userToConnections[userId].Count}");
            }
        }

        public void RemoveConnection(string connectionId)
        {
            lock (_lock)
            {
                if (_connectionToUser.TryRemove(connectionId, out int userId))
                {
                    if (_userToConnections.ContainsKey(userId))
                    {
                        _userToConnections[userId].Remove(connectionId);

                        // If user has no more connections, remove the entry
                        if (_userToConnections[userId].Count == 0)
                        {
                            _userToConnections.TryRemove(userId, out _);
                            Console.WriteLine($"[ConnectionManager] User {userId} is now offline (all connections closed)");
                        }
                        else
                        {
                            Console.WriteLine($"[ConnectionManager] User {userId} disconnected one device. Remaining connections: {_userToConnections[userId].Count}");
                        }
                    }
                }
            }
        }

        public List<string> GetUserConnections(int userId)
        {
            if (_userToConnections.TryGetValue(userId, out var connections))
            {
                return connections.ToList();
            }
            return new List<string>();
        }

        public int? GetUserIdByConnection(string connectionId)
        {
            if (_connectionToUser.TryGetValue(connectionId, out int userId))
            {
                return userId;
            }
            return null;
        }

        public bool IsUserOnline(int userId)
        {
            return _userToConnections.ContainsKey(userId) && _userToConnections[userId].Count > 0;
        }

        public void UpdateLastSeen(int userId)
        {
            // This will be called when user disconnects
            // You can implement additional logic here if needed
            Console.WriteLine($"[ConnectionManager] Updating last seen for user {userId}");
        }
    }
}
