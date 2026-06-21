class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.teamId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.authorName,
    this.authorAvatar,
  });

  final String id;
  final String teamId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String? authorName;
  final String? authorAvatar;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return ChatMessage(
      id: json['id'] as String,
      teamId: json['team_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      authorName: profile?['full_name'] as String?,
      authorAvatar: profile?['avatar_url'] as String?,
    );
  }
}
