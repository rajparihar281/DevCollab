class Project {
  const Project({
    required this.id,
    required this.organizationId,
    required this.teamId,
    required this.name,
    this.description,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String organizationId;
  final String teamId;
  final String name;
  final String? description;
  final String status; // active, archived
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive => status == 'active';

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      teamId: json['team_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'active',
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'organization_id': organizationId,
        'team_id': teamId,
        'name': name,
        'description': description,
        'status': status,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
