class ApiConfig {
  // Change this to your server URL
  static const String baseUrl = 'http://127.0.0.1:5014'; // Android emulator
  // static const String baseUrl = 'http://localhost:5014'; // iOS simulator
  // static const String baseUrl = 'http://192.168.1.100:5014'; // Physical device

  // REST API Endpoints
  static const String loginUrl = '$baseUrl/api/Auth/login';
  static const String registerUrl = '$baseUrl/api/Auth/register';
  static const String myChatsUrl = '$baseUrl/api/Chat/my-chats';
  static String getChatMessagesUrl(int chatId) =>
      '$baseUrl/api/Message/chat/$chatId';
  static String sendMessageUrl(int chatId) =>
      '$baseUrl/api/Message/chat/$chatId/send';
  static String uploadFileUrl(int chatId) =>
      '$baseUrl/api/Message/chat/$chatId/upload';
  static String deleteMessageUrl(int messageId) =>
      '$baseUrl/api/Message/$messageId';
  static String deleteChatUrl(int chatId) => '$baseUrl/api/Chat/$chatId';
  static String leaveGroupUrl(int chatId) =>
      '$baseUrl/api/Chat/group/$chatId/leave';
  static String markMessagesAsDeliveredUrl(int chatId) =>
      '$baseUrl/api/Message/chat/$chatId/delivered';
  static String markMessageAsSeenUrl(int messageId) =>
      '$baseUrl/api/Message/$messageId/seen';

  // SignalR Hub
  static const String chatHubUrl = '$baseUrl/chatHub';

  // Settings
  static const int messagePageSize = 50;
  static const Duration connectionTimeout = Duration(seconds: 30);
}
