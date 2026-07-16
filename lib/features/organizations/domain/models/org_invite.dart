class OrgInvite {
  const OrgInvite({
    required this.id,
    required this.orgId,
    required this.inviteCode,
    required this.role,
    this.createdBy,
    this.createdAt,
  });

  final String id;
  final String orgId;
  final String inviteCode;
  final String role; // 'admin' or 'member'
  final String? createdBy;
  final DateTime? createdAt;

  factory OrgInvite.fromJson(Map<String, dynamic> json) {
    return OrgInvite(
      id: json['id'] as String,
      orgId: json['org_id'] as String,
      inviteCode: json['invite_code'] as String,
      role: json['role'] as String? ?? 'member',
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'org_id': orgId,
      'invite_code': inviteCode,
      'role': role,
      if (createdBy != null) 'created_by': createdBy,
    };
  }
}
