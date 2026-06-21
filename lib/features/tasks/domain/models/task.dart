class Task {
  const Task({
    required this.id,
    required this.organizationId,
    required this.projectId,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.assigneeId,
    required this.createdBy,
    this.dueDate,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
    this.assigneeName,
    this.assigneeAvatar,
    this.creatorName,
  });

  final String id;
  final String organizationId;
  final String projectId;
  final String title;
  final String? description;
  final String status; // todo, in_progress, review, done
  final String priority; // low, medium, high, critical
  final String? assigneeId;
  final String createdBy;
  final DateTime? dueDate;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields
  final String? assigneeName;
  final String? assigneeAvatar;
  final String? creatorName;

  factory Task.fromJson(Map<String, dynamic> json) {
    final assignee = json['assignee'] as Map<String, dynamic>?;
    final creator = json['creator'] as Map<String, dynamic>?;
    return Task(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      projectId: json['project_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'todo',
      priority: json['priority'] as String? ?? 'medium',
      assigneeId: json['assignee_id'] as String?,
      createdBy: json['created_by'] as String,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      position: json['position'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      assigneeName: assignee?['full_name'] as String?,
      assigneeAvatar: assignee?['avatar_url'] as String?,
      creatorName: creator?['full_name'] as String?,
    );
  }

  Task copyWith({
    String? status,
    String? priority,
    String? title,
    String? description,
    String? assigneeId,
    DateTime? dueDate,
    int? position,
  }) {
    return Task(
      id: id,
      organizationId: organizationId,
      projectId: projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assigneeId: assigneeId ?? this.assigneeId,
      createdBy: createdBy,
      dueDate: dueDate ?? this.dueDate,
      position: position ?? this.position,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      assigneeName: assigneeName,
      assigneeAvatar: assigneeAvatar,
      creatorName: creatorName,
    );
  }
}
