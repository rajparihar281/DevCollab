class KanbanProject {
  const KanbanProject({
    required this.id,
    required this.orgId,
    required this.title,
    this.description,
    this.createdAt,
  });

  final String id;
  final String orgId;
  final String title;
  final String? description;
  final DateTime? createdAt;

  factory KanbanProject.fromJson(Map<String, dynamic> json) {
    return KanbanProject(
      id: json['id'] as String,
      orgId: json['org_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'org_id': orgId,
      'title': title,
      if (description != null) 'description': description,
    };
  }
}
