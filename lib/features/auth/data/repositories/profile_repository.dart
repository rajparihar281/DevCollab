import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/profile.dart';

class ProfileRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Profile?> getCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return Profile.fromJson(response);
  }

  Future<Profile?> getProfileById(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return Profile.fromJson(response);
  }

  Future<List<Profile>> getProfilesByIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    final response = await _client
        .from('profiles')
        .select()
        .inFilter('id', userIds);
    return response.map<Profile>((j) => Profile.fromJson(j)).toList();
  }

  Future<Profile> upsertProfile({
    required String fullName,
    String? avatarUrl,
  }) async {
    final user = _client.auth.currentUser!;
    final now = DateTime.now().toIso8601String();

    final response = await _client
        .from('profiles')
        .upsert({
          'id': user.id,
          'full_name': fullName,
          'avatar_url': avatarUrl,
          'created_at': now,
          'updated_at': now,
        })
        .select()
        .single();

    return Profile.fromJson(response);
  }
}
