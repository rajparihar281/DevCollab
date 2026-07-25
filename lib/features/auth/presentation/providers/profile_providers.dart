import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/profile_repository.dart';
import '../../domain/models/profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final allProfilesProvider = FutureProvider<List<Profile>>((ref) async {
  final repo = ref.read(profileRepositoryProvider);
  return repo.getAllProfiles();
});

final searchProfilesProvider =
    FutureProvider.family<List<Profile>, String>((ref, query) async {
  final repo = ref.read(profileRepositoryProvider);
  return repo.searchProfiles(query);
});
