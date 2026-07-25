class OrganizationMember {
  const OrganizationMember({
    required this.id,
    required this.organizationId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.fullName,
    this.avatarUrl,
    this.email,
  });

  final String id;
  final String organizationId;
  final String userId;
  final String role; // owner, admin, member, viewer
  final DateTime joinedAt;

  // Joined from profiles
  final String? fullName;
  final String? avatarUrl;
  final String? email;

  factory OrganizationMember.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return OrganizationMember(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      fullName: profile?['full_name'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
    );
  }

  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin';
  bool get canManage => role == 'owner' || role == 'admin';
}
