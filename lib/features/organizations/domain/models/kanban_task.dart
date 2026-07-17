class KanbanTask {
  const KanbanTask({
    required this.id,
    this.projectId,
    required this.orgId,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.assigneeId,
    this.assigneeName,
    this.assigneeAvatar,
    this.dueDate,
    this.createdAt,
  });

  final String id;
  final String? projectId;
  final String orgId;
  final String title;
  final String? description;
  final String status; // 'todo', 'in_progress', 'code_review', 'done'
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final String? assigneeId;
  final String? assigneeName;
  final String? assigneeAvatar;
  final DateTime? dueDate;
  final DateTime? createdAt;

  factory KanbanTask.fromJson(Map<String, dynamic> json) {
    return KanbanTask(
      id: json['id'] as String,
      projectId: json['project_id'] as String?,
      orgId: json['org_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'todo',
      priority: json['priority'] as String? ?? 'medium',
      assigneeId: json['assignee_id'] as String?,
      assigneeName: json['assignee_name'] as String?,
      assigneeAvatar: json['assignee_avatar'] as String?,
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (projectId != null) 'project_id': projectId,
      'org_id': orgId,
      'title': title,
      if (description != null) 'description': description,
      'status': status,
      'priority': priority,
      if (assigneeId != null) 'assignee_id': assigneeId,
      if (assigneeName != null) 'assignee_name': assigneeName,
      if (assigneeAvatar != null) 'assignee_avatar': assigneeAvatar,
      if (dueDate != null)
        'due_date': dueDate!.toIso8601String().substring(0, 10),
    };
  }

  KanbanTask copyWith({
    String? title,
    String? description,
    String? status,
    String? priority,
    String? assigneeId,
    String? assigneeName,
    String? assigneeAvatar,
    DateTime? dueDate,
  }) {
    return KanbanTask(
      id: id,
      projectId: projectId,
      orgId: orgId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assigneeId: assigneeId ?? this.assigneeId,
      assigneeName: assigneeName ?? this.assigneeName,
      assigneeAvatar: assigneeAvatar ?? this.assigneeAvatar,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt,
    );
  }
}
