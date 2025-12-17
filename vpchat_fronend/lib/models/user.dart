class User {
  final int id;
  final String username;
  final bool isOnline;
  final DateTime? lastSeen;

  User({
    required this.id,
    required this.username,
    required this.isOnline,
    this.lastSeen,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? username,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}
