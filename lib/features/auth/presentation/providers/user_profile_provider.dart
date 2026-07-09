import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/profile.dart';
import 'auth_provider.dart';

final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, Profile?>(UserProfileNotifier.new);

class UserProfileNotifier extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    final authRepo = ref.watch(authRepositoryProvider);
    final user = authRepo.currentUser;
    if (user == null) return null;
    return authRepo.getProfile(user.id);
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    final authRepo = ref.read(authRepositoryProvider);
    final user = authRepo.currentUser;
    if (user == null) return;
    await authRepo.updateProfile(user.id, updates);
    ref.invalidateSelf();
    await future;
  }

  Future<String?> uploadAvatar(File file) async {
    final authRepo = ref.read(authRepositoryProvider);
    final user = authRepo.currentUser;
    if (user == null) return null;

    final url = await authRepo.uploadProfilePicture(file, user.id);
    await updateProfile({
      'avatar_url': url,
      'updated_at': DateTime.now().toIso8601String(),
    });
    return url;
  }
}
