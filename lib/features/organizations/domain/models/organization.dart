class Organization {
  const Organization({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String ownerId;
  final DateTime createdAt;

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] as String,
      name: json['name'] as String,
      ownerId: json['owner_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'owner_id': ownerId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
