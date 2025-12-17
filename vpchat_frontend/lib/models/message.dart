import 'user.dart';

enum MessageType { text, image, audio, video, file }

enum MessageStatus { sent, delivered, seen }

/// Represents a reaction to a message
class MessageReaction {
  final String emoji;
  final User user;
  final DateTime reactedAt;

  MessageReaction({
    required this.emoji,
    required this.user,
    required this.reactedAt,
  });

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      emoji: json['emoji'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      reactedAt: DateTime.parse(json['reactedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'emoji': emoji,
    'user': user.toJson(),
    'reactedAt': reactedAt.toIso8601String(),
  };
}

/// Represents a reply reference to another message
class ReplyTo {
  final int messageId;
  final String senderName;
  final String? content;
  final MessageType messageType;

  ReplyTo({
    required this.messageId,
    required this.senderName,
    this.content,
    required this.messageType,
  });

  factory ReplyTo.fromJson(Map<String, dynamic> json) {
    return ReplyTo(
      messageId: json['messageId'] as int,
      senderName: json['senderName'] as String,
      content: json['content'] as String?,
      messageType: MessageType.values[json['messageType'] as int? ?? 0],
    );
  }

  Map<String, dynamic> toJson() => {
    'messageId': messageId,
    'senderName': senderName,
    'content': content,
    'messageType': messageType.index,
  };

  String get previewText {
    switch (messageType) {
      case MessageType.image:
        return '📷 Photo';
      case MessageType.video:
        return '🎥 Video';
      case MessageType.audio:
        return '🎵 Audio';
      case MessageType.file:
        return '📎 File';
      case MessageType.text:
        return content ?? '';
    }
  }
}

class Message {
  final int id;
  final int chatId;
  final User sender;
  final String? content;
  final MessageType messageType;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final DateTime sentAt;
  final MessageStatus status;
  final ReplyTo? replyTo;
  final List<MessageReaction> reactions;
  final int? audioDuration; // Duration in seconds for voice messages

  Message({
    required this.id,
    required this.chatId,
    required this.sender,
    this.content,
    required this.messageType,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    required this.sentAt,
    required this.status,
    this.replyTo,
    this.reactions = const [],
    this.audioDuration,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as int,
      chatId: json['chatId'] as int,
      sender: User.fromJson(json['sender'] as Map<String, dynamic>),
      content: json['content'] as String?,
      messageType: MessageType.values[json['messageType'] as int],
      fileUrl: json['fileUrl'] as String?,
      fileName: json['fileName'] as String?,
      fileSize: json['fileSize'] as int?,
      sentAt: DateTime.parse(json['sentAt'] as String),
      status: MessageStatus.values[json['status'] as int],
      replyTo: json['replyTo'] != null
          ? ReplyTo.fromJson(json['replyTo'] as Map<String, dynamic>)
          : null,
      reactions:
          (json['reactions'] as List<dynamic>?)
              ?.map((r) => MessageReaction.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      audioDuration: json['audioDuration'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'sender': sender.toJson(),
      'content': content,
      'messageType': messageType.index,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'sentAt': sentAt.toIso8601String(),
      'status': status.index,
      'replyTo': replyTo?.toJson(),
      'reactions': reactions.map((r) => r.toJson()).toList(),
      'audioDuration': audioDuration,
    };
  }

  /// Create a copy with updated fields
  Message copyWith({
    int? id,
    int? chatId,
    User? sender,
    String? content,
    MessageType? messageType,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    DateTime? sentAt,
    MessageStatus? status,
    ReplyTo? replyTo,
    List<MessageReaction>? reactions,
    int? audioDuration,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      sentAt: sentAt ?? this.sentAt,
      status: status ?? this.status,
      replyTo: replyTo ?? this.replyTo,
      reactions: reactions ?? this.reactions,
      audioDuration: audioDuration ?? this.audioDuration,
    );
  }

  bool get isVoiceMessage =>
      messageType == MessageType.audio && audioDuration != null;
  bool get hasReactions => reactions.isNotEmpty;
  bool get isReply => replyTo != null;
}
