import 'user.dart';
import 'message.dart';

enum ChatType { oneToOne, group }

class Chat {
  final int id;
  final ChatType type;
  final String? name;
  final DateTime createdAt;
  final bool isActive;
  final List<User> participants;
  final Message? lastMessage;

  Chat({
    required this.id,
    required this.type,
    this.name,
    required this.createdAt,
    required this.isActive,
    required this.participants,
    this.lastMessage,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] as int,
      type: ChatType.values[json['type'] as int],
      name: json['name'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool,
      participants: (json['participants'] as List)
          .map((p) => User.fromJson(p as Map<String, dynamic>))
          .toList(),
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
    );
  }

  String getDisplayName(int currentUserId) {
    if (type == ChatType.group) {
      return name ?? 'Unnamed Group';
    }

    // For one-to-one, show the other person's name
    final otherUser = participants.firstWhere(
      (user) => user.id != currentUserId,
      orElse: () => participants.first,
    );
    return otherUser.username;
  }

  /// Create a copy with updated fields
  Chat copyWith({
    int? id,
    ChatType? type,
    String? name,
    DateTime? createdAt,
    bool? isActive,
    List<User>? participants,
    Message? lastMessage,
  }) {
    return Chat(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }
}
