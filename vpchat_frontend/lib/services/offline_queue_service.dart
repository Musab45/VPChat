import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to queue messages when offline and send them when back online
class OfflineQueueService {
  static const String _queueKey = 'offline_message_queue';

  /// Add a message to the offline queue
  Future<void> queueMessage(QueuedMessage message) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = await getQueuedMessages();
    queue.add(message);
    await prefs.setString(
      _queueKey,
      jsonEncode(queue.map((m) => m.toJson()).toList()),
    );
  }

  /// Get all queued messages
  Future<List<QueuedMessage>> getQueuedMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = prefs.getString(_queueKey);
    if (queueJson == null || queueJson.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(queueJson);
      return decoded.map((json) => QueuedMessage.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Remove a message from the queue (after successful send)
  Future<void> removeFromQueue(String messageId) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = await getQueuedMessages();
    queue.removeWhere((m) => m.id == messageId);
    await prefs.setString(
      _queueKey,
      jsonEncode(queue.map((m) => m.toJson()).toList()),
    );
  }

  /// Clear the entire queue
  Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queueKey);
  }

  /// Get queue count
  Future<int> getQueueCount() async {
    final queue = await getQueuedMessages();
    return queue.length;
  }

  /// Check if there are pending messages
  Future<bool> hasPendingMessages() async {
    final count = await getQueueCount();
    return count > 0;
  }
}

/// Represents a message waiting to be sent
class QueuedMessage {
  final String id;
  final int chatId;
  final String content;
  final int messageType;
  final DateTime queuedAt;
  final int retryCount;
  final String? filePath;

  QueuedMessage({
    required this.id,
    required this.chatId,
    required this.content,
    this.messageType = 0,
    required this.queuedAt,
    this.retryCount = 0,
    this.filePath,
  });

  factory QueuedMessage.fromJson(Map<String, dynamic> json) {
    return QueuedMessage(
      id: json['id'] as String,
      chatId: json['chatId'] as int,
      content: json['content'] as String,
      messageType: json['messageType'] as int? ?? 0,
      queuedAt: DateTime.parse(json['queuedAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
      filePath: json['filePath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'content': content,
      'messageType': messageType,
      'queuedAt': queuedAt.toIso8601String(),
      'retryCount': retryCount,
      'filePath': filePath,
    };
  }

  QueuedMessage copyWith({int? retryCount}) {
    return QueuedMessage(
      id: id,
      chatId: chatId,
      content: content,
      messageType: messageType,
      queuedAt: queuedAt,
      retryCount: retryCount ?? this.retryCount,
      filePath: filePath,
    );
  }
}
