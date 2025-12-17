import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/signalr_service.dart';
import '../services/connectivity_service.dart';
import '../config/api_config.dart';

class ChatProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SignalRService _signalRService = SignalRService();
  final ConnectivityService _connectivityService = ConnectivityService();

  List<Chat> _chats = [];
  Map<int, List<Message>> _messagesByChat = {};
  Map<int, bool> _typingUsers = {};
  Map<int, int> _currentPageByChat = {}; // Track current page for each chat
  Map<int, bool> _hasMoreMessagesByChat =
      {}; // Track if there are more messages to load
  Map<int, bool> _isLoadingMoreMessages =
      {}; // Track loading state for pagination

  bool _isConnected = false;
  bool _isLoading = false;
  bool _isOnline = true;
  String? _error;
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  bool _shouldStopReconnecting = false;

  List<Chat> get chats => _chats;
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;
  bool get isReconnecting => _isReconnecting;
  String? get error => _error;
  int get reconnectAttempts => _reconnectAttempts;

  List<Message> getMessages(int chatId) => _messagesByChat[chatId] ?? [];
  bool isUserTyping(int chatId) => _typingUsers[chatId] ?? false;
  bool hasMoreMessages(int chatId) => _hasMoreMessagesByChat[chatId] ?? true;
  bool isLoadingMoreMessages(int chatId) =>
      _isLoadingMoreMessages[chatId] ?? false;

  void _notifyListeners() {
    // Use addPostFrameCallback to avoid calling notifyListeners during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> initialize(String token, User user) async {
    // Initialize connectivity service
    await _connectivityService.initialize();
    _isOnline = _connectivityService.isOnline;

    // Listen to connectivity changes
    _connectivityService.onConnectivityChanged = (isOnline) {
      _isOnline = isOnline;
      notifyListeners();

      if (isOnline) {
        print('📡 Network restored - attempting to reconnect...');
        _handleNetworkRestored();
      } else {
        print('📡 Network lost');
        _isConnected = false;
        notifyListeners();
      }
    };

    await connectToSignalR();
    await loadChats();
  }

  Future<void> _handleNetworkRestored() async {
    // Reset reconnection state when network is restored
    _reconnectAttempts = 0;
    _shouldStopReconnecting = false;

    // Try to reconnect SignalR
    if (!_isConnected) {
      try {
        _isReconnecting = true;
        notifyListeners();

        await connectToSignalR();

        // Rejoin all active chats
        for (var chatId in _messagesByChat.keys) {
          if (_isConnected) {
            await _signalRService.joinChat(chatId);
          }
        }

        _isReconnecting = false;
        notifyListeners();
      } catch (e) {
        _isReconnecting = false;
        print('❌ Failed to reconnect: $e');
        notifyListeners();
      }
    }
  }

  Future<void> connectToSignalR() async {
    if (!_isOnline) {
      _error = 'No internet connection';
      _isConnected = false;
      notifyListeners();
      return;
    }

    try {
      // Setup event handlers
      _signalRService.onMessageReceived = _handleMessageReceived;
      _signalRService.onUserTyping = _handleUserTyping;
      _signalRService.onMessageStatusUpdate = _handleMessageStatusUpdate;
      _signalRService.onConnected = () {
        _isConnected = true;
        _isReconnecting = false;
        _reconnectAttempts = 0; // Reset on successful connection
        _shouldStopReconnecting = false;
        _error = null;
        print('✅ SignalR connected');
        notifyListeners();
      };
      _signalRService.onDisconnected = () {
        _isConnected = false;
        print('❌ SignalR disconnected');
        notifyListeners();

        // Only try to reconnect if we haven't exceeded max attempts and should continue
        if (_isOnline &&
            !_shouldStopReconnecting &&
            _reconnectAttempts < _maxReconnectAttempts) {
          _reconnectAttempts++;

          // Exponential backoff: 2s, 4s, 8s, 16s, 32s
          final delaySeconds = (2 * (1 << (_reconnectAttempts - 1))).clamp(
            2,
            32,
          );

          print(
            '🔄 Attempting auto-reconnect (${_reconnectAttempts}/$_maxReconnectAttempts) in ${delaySeconds}s...',
          );

          Future.delayed(Duration(seconds: delaySeconds), () {
            if (!_isConnected && _isOnline && !_shouldStopReconnecting) {
              connectToSignalR();
            }
          });
        } else if (_reconnectAttempts >= _maxReconnectAttempts) {
          _error =
              'Failed to connect after $_maxReconnectAttempts attempts. Tap retry to try again.';
          _isReconnecting = false;
          print('❌ Max reconnect attempts reached');
          notifyListeners();
        }
      };
      _signalRService.onError = (error) {
        // Check if it's a connection refused error (server not available)
        if (error.contains('Connection refused') ||
            error.contains('Failed host lookup') ||
            error.contains('Connection reset')) {
          _shouldStopReconnecting = true;
          _error =
              'Cannot connect to server. Please ensure the server is running.';
          _isReconnecting = false;
          print('❌ Server unavailable - stopping reconnection attempts');
        } else {
          _error = error;
        }
        print('❌ SignalR error: $error');
        notifyListeners();
      };

      await _signalRService.connect();
      _isConnected = true;
      _error = null;
      _reconnectAttempts = 0;
      _shouldStopReconnecting = false;
      notifyListeners();
    } catch (e) {
      final errorMessage = e.toString();

      // Check if it's a connection refused error
      if (errorMessage.contains('Connection refused') ||
          errorMessage.contains('Failed host lookup') ||
          errorMessage.contains('SocketException')) {
        _shouldStopReconnecting = true;
        _error =
            'Cannot connect to server. Please ensure the server is running.';
        _isReconnecting = false;
        print('❌ Server unavailable - stopping reconnection attempts');
      } else {
        _error = 'Failed to connect to chat server';
      }

      _isConnected = false;
      print('❌ SignalR connection failed: $e');
      notifyListeners();
    }
  }

  Future<void> loadChats() async {
    try {
      _isLoading = true;
      _notifyListeners();

      _chats = await _apiService.getMyChats();

      _isLoading = false;
      _notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _notifyListeners();
    }
  }

  Future<void> loadMessages(int chatId) async {
    try {
      _isLoading = true;
      _notifyListeners();

      final messages = await _apiService.getChatMessages(chatId, page: 1);
      _messagesByChat[chatId] = messages.reversed.toList(); // Newest last
      _currentPageByChat[chatId] = 1;
      _hasMoreMessagesByChat[chatId] =
          messages.length >= ApiConfig.messagePageSize;
      _isLoadingMoreMessages[chatId] = false;

      _notifyListeners();

      // Join SignalR group
      if (_isConnected) {
        await _signalRService.joinChat(chatId);
      }
    } catch (e) {
      _error = e.toString();
      _notifyListeners();
    } finally {
      _isLoading = false;
      _notifyListeners();
    }
  }

  Future<void> loadMoreMessages(int chatId) async {
    if (_isLoadingMoreMessages[chatId] == true ||
        !(_hasMoreMessagesByChat[chatId] ?? true)) {
      return; // Already loading or no more messages
    }

    try {
      _isLoadingMoreMessages[chatId] = true;
      _notifyListeners();

      final currentPage = _currentPageByChat[chatId] ?? 1;
      final nextPage = currentPage + 1;

      final newMessages = await _apiService.getChatMessages(
        chatId,
        page: nextPage,
      );

      if (newMessages.isNotEmpty) {
        // Add older messages to the beginning (they come in reverse chronological order)
        final existingMessages = _messagesByChat[chatId] ?? [];
        _messagesByChat[chatId] = [
          ...newMessages.reversed,
          ...existingMessages,
        ];
        _currentPageByChat[chatId] = nextPage;
        _hasMoreMessagesByChat[chatId] =
            newMessages.length >= ApiConfig.messagePageSize;
      } else {
        _hasMoreMessagesByChat[chatId] = false;
      }

      _notifyListeners();
    } catch (e) {
      _error = 'Failed to load more messages: $e';
      _notifyListeners();
    } finally {
      _isLoadingMoreMessages[chatId] = false;
      _notifyListeners();
    }
  }

  Future<void> sendMessage(int chatId, String content) async {
    try {
      if (_isConnected) {
        // Send via SignalR (real-time)
        await _signalRService.sendMessage(chatId, content);
      } else {
        // Fallback to REST API
        final message = await _apiService.sendMessage(chatId, content);
        _handleMessageReceived(message);
      }
    } catch (e) {
      _error = 'Failed to send message: $e';
      notifyListeners();
    }
  }

  void sendTypingIndicator(int chatId, bool isTyping) {
    if (_isConnected) {
      _signalRService.sendTypingIndicator(chatId, isTyping);
    }
  }

  // Manual retry - resets all reconnection state
  Future<void> retryConnection() async {
    print('🔄 Manual retry requested');
    _reconnectAttempts = 0;
    _shouldStopReconnecting = false;
    _error = null;
    _isReconnecting = true;
    notifyListeners();

    await connectToSignalR();

    // Rejoin all active chats if connection successful
    if (_isConnected) {
      for (var chatId in _messagesByChat.keys) {
        await _signalRService.joinChat(chatId);
      }
    }

    _isReconnecting = false;
    notifyListeners();
  }

  void addMessage(Message message) {
    _handleMessageReceived(message);
  }

  void _handleMessageReceived(Message message) {
    if (!_messagesByChat.containsKey(message.chatId)) {
      _messagesByChat[message.chatId] = [];
    }
    _messagesByChat[message.chatId]!.add(message);

    // Update last message in chat list
    final chatIndex = _chats.indexWhere((c) => c.id == message.chatId);
    if (chatIndex != -1) {
      // Move chat to top
      final chat = _chats.removeAt(chatIndex);
      _chats.insert(0, chat);
    }

    notifyListeners();
  }

  void _handleUserTyping(int userId, bool isTyping) {
    // Update typing status
    _typingUsers[userId] = isTyping;
    notifyListeners();

    // Auto-clear after 3 seconds
    if (isTyping) {
      Future.delayed(const Duration(seconds: 3), () {
        _typingUsers[userId] = false;
        notifyListeners();
      });
    }
  }

  void _handleMessageStatusUpdate(
    int chatId,
    List<int> messageIds,
    int status,
  ) {
    final messageStatus = MessageStatus.values[status];
    updateMessagesStatus(chatId, messageIds, messageStatus);
  }

  Future<void> leaveChat(int chatId) async {
    if (_isConnected) {
      await _signalRService.leaveChat(chatId);
    }
  }

  void removeMessage(int chatId, int messageId) {
    if (_messagesByChat.containsKey(chatId)) {
      _messagesByChat[chatId]!.removeWhere((msg) => msg.id == messageId);
      notifyListeners();
    }
  }

  void updateMessageStatus(int chatId, int messageId, MessageStatus newStatus) {
    if (_messagesByChat.containsKey(chatId)) {
      final messages = _messagesByChat[chatId]!;
      final messageIndex = messages.indexWhere((msg) => msg.id == messageId);
      if (messageIndex != -1) {
        final updatedMessage = Message(
          id: messages[messageIndex].id,
          chatId: messages[messageIndex].chatId,
          sender: messages[messageIndex].sender,
          content: messages[messageIndex].content,
          messageType: messages[messageIndex].messageType,
          fileUrl: messages[messageIndex].fileUrl,
          fileName: messages[messageIndex].fileName,
          fileSize: messages[messageIndex].fileSize,
          sentAt: messages[messageIndex].sentAt,
          status: newStatus,
        );
        messages[messageIndex] = updatedMessage;
        notifyListeners();
      }
    }
  }

  void updateMessagesStatus(
    int chatId,
    List<int> messageIds,
    MessageStatus newStatus,
  ) {
    if (_messagesByChat.containsKey(chatId)) {
      final messages = _messagesByChat[chatId]!;
      bool hasUpdates = false;

      for (final messageId in messageIds) {
        final messageIndex = messages.indexWhere((msg) => msg.id == messageId);
        if (messageIndex != -1 &&
            messages[messageIndex].status.index < newStatus.index) {
          final updatedMessage = Message(
            id: messages[messageIndex].id,
            chatId: messages[messageIndex].chatId,
            sender: messages[messageIndex].sender,
            content: messages[messageIndex].content,
            messageType: messages[messageIndex].messageType,
            fileUrl: messages[messageIndex].fileUrl,
            fileName: messages[messageIndex].fileName,
            fileSize: messages[messageIndex].fileSize,
            sentAt: messages[messageIndex].sentAt,
            status: newStatus,
          );
          messages[messageIndex] = updatedMessage;
          hasUpdates = true;
        }
      }

      if (hasUpdates) {
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _signalRService.dispose();
    _connectivityService.dispose();
    super.dispose();
  }
}
