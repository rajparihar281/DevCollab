class Profile {
  const Profile({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.username,
    this.bio,
    this.dob,
    this.jobTitle,
    this.currentCompany,
    this.teams = const [],
    this.notifyTaskAssigned = true,
    this.notifyMention = true,
    this.notifyTeamMessage = true,
    this.notifyEmailDigest = false,
    this.notifySecurityAlerts = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? username;
  final String? bio;
  final DateTime? dob;
  final String? jobTitle;
  final String? currentCompany;
  final List<String> teams;
  final bool notifyTaskAssigned;
  final bool notifyMention;
  final bool notifyTeamMessage;
  final bool notifyEmailDigest;
  final bool notifySecurityAlerts;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      username: json['username'] as String?,
      bio: json['bio'] as String?,
      dob: json['dob'] != null ? DateTime.tryParse(json['dob'] as String) : null,
      jobTitle: json['job_title'] as String?,
      currentCompany: json['current_company'] as String?,
      teams: (json['teams'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      notifyTaskAssigned: json['notify_task_assigned'] as bool? ?? true,
      notifyMention: json['notify_mention'] as bool? ?? true,
      notifyTeamMessage: json['notify_team_message'] as bool? ?? true,
      notifyEmailDigest: json['notify_email_digest'] as bool? ?? false,
      notifySecurityAlerts: json['notify_security_alerts'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'username': username,
      'bio': bio,
      'dob': dob?.toIso8601String().split('T').first,
      'job_title': jobTitle,
      'current_company': currentCompany,
      'teams': teams,
      'notify_task_assigned': notifyTaskAssigned,
      'notify_mention': notifyMention,
      'notify_team_message': notifyTeamMessage,
      'notify_email_digest': notifyEmailDigest,
      'notify_security_alerts': notifySecurityAlerts,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Profile copyWith({
    String? fullName,
    String? avatarUrl,
    String? username,
    String? bio,
    DateTime? dob,
    String? jobTitle,
    String? currentCompany,
    List<String>? teams,
    bool? notifyTaskAssigned,
    bool? notifyMention,
    bool? notifyTeamMessage,
    bool? notifyEmailDigest,
    bool? notifySecurityAlerts,
  }) {
    return Profile(
      id: id,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      dob: dob ?? this.dob,
      jobTitle: jobTitle ?? this.jobTitle,
      currentCompany: currentCompany ?? this.currentCompany,
      teams: teams ?? this.teams,
      notifyTaskAssigned: notifyTaskAssigned ?? this.notifyTaskAssigned,
      notifyMention: notifyMention ?? this.notifyMention,
      notifyTeamMessage: notifyTeamMessage ?? this.notifyTeamMessage,
      notifyEmailDigest: notifyEmailDigest ?? this.notifyEmailDigest,
      notifySecurityAlerts: notifySecurityAlerts ?? this.notifySecurityAlerts,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
