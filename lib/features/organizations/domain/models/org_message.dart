class OrgMessage {
  const OrgMessage({
    required this.id,
    required this.orgId,
    this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    required this.isAnnouncement,
    this.createdAt,
  });

  final String id;
  final String orgId;
  final String? userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final bool isAnnouncement;
  final DateTime? createdAt;

  factory OrgMessage.fromJson(Map<String, dynamic> json) {
    return OrgMessage(
      id: json['id'] as String,
      orgId: json['org_id'] as String,
      userId: json['user_id'] as String?,
      userName: json['user_name'] as String? ?? 'Team Member',
      userAvatar: json['user_avatar'] as String?,
      content: json['content'] as String? ?? '',
      isAnnouncement: json['is_announcement'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'org_id': orgId,
      if (userId != null) 'user_id': userId,
      'user_name': userName,
      if (userAvatar != null) 'user_avatar': userAvatar,
      'content': content,
      'is_announcement': isAnnouncement,
    };
  }
}
