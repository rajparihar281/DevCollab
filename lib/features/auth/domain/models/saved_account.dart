class SavedAccount {
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String securePassword;
  final DateTime lastLoginAt;

  const SavedAccount({
    required this.email,
    required this.fullName,
    this.avatarUrl,
    required this.securePassword,
    required this.lastLoginAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'fullName': fullName,
      'avatarUrl': avatarUrl,
      'lastLoginAt': lastLoginAt.toIso8601String(),
    };
  }

  factory SavedAccount.fromJson(Map<String, dynamic> json, String password) {
    return SavedAccount(
      email: json['email'] as String,
      fullName: json['fullName'] as String? ?? json['email'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      securePassword: password,
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : DateTime.now(),
    );
  }
}
