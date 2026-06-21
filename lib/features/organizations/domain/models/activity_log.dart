class ActivityLog {
  const ActivityLog({
    required this.id,
    required this.organizationId,
    required this.userId,
    required this.entityType,
    required this.entityId,
    required this.action,
    this.metadata,
    required this.createdAt,
    this.actorName,
    this.actorAvatar,
  });

  final String id;
  final String organizationId;
  final String userId;
  final String entityType; // project, task, comment, etc.
  final String entityId;
  final String action; // create, update, delete, move
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final String? actorName;
  final String? actorAvatar;

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return ActivityLog(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      userId: json['user_id'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      action: json['action'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      actorName: profile?['full_name'] as String?,
      actorAvatar: profile?['avatar_url'] as String?,
    );
  }

  String get summary {
    final actor = actorName ?? 'Someone';
    switch (action) {
      case 'create':
        return '$actor created a $entityType';
      case 'update':
        return '$actor updated a $entityType';
      case 'delete':
        return '$actor deleted a $entityType';
      case 'move':
        return '$actor moved a $entityType';
      default:
        return '$actor performed $action on $entityType';
    }
  }
}
