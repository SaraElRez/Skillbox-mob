class Conversation {
  final int id;
  final int user1Id;
  final int user2Id;
  final String? lastMessageSnippet;
  final DateTime updatedAt;
  final String otherUserName;
  final int otherUserId;
  final String otherUserEmail;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    this.lastMessageSnippet,
    required this.updatedAt,
    required this.otherUserName,
    required this.otherUserId,
    required this.otherUserEmail,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] ?? 0,
      user1Id: json['user1_id'] ?? 0,
      user2Id: json['user2_id'] ?? 0,
      lastMessageSnippet: json['last_message_snippet'],
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toString()),
      otherUserName: json['other_user_name'] ?? 'Unknown',
      otherUserId: json['other_user_id'] ?? 0,
      otherUserEmail: json['other_user_email'] ?? '',
      unreadCount: int.parse(json['unread_count']?.toString() ?? '0'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user1_id': user1Id,
      'user2_id': user2Id,
      'last_message_snippet': lastMessageSnippet,
      'updated_at': updatedAt.toIso8601String(),
      'other_user_name': otherUserName,
      'other_user_id': otherUserId,
      'other_user_email': otherUserEmail,
      'unread_count': unreadCount,
    };
  }
}

