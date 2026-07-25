import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/organization_member.dart';

class OrganizationMemberRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<OrganizationMember>> getMembers(String organizationId) async {

    try {
      final response = await _client
          .from('organization_members')
          .select('*, profiles(full_name, avatar_url)')
          .eq('organization_id', organizationId)
          .order('joined_at');

      final members = response
          .map<OrganizationMember>((json) => OrganizationMember.fromJson(json))
          .toList();

      return members;
    } catch (e) {

      rethrow;
    }
  }

  Future<OrganizationMember?> getCurrentUserMember(String organizationId) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;


    try {
      final response = await _client
          .from('organization_members')
          .select('*, profiles(full_name, avatar_url)')
          .eq('organization_id', organizationId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) {

        return null;
      }
      return OrganizationMember.fromJson(response);
    } catch (e) {

      rethrow;
    }
  }

  Future<void> addMember({
    required String organizationId,
    required String userId,
    String role = 'member',
  }) async {

    try {
      await _client.from('organization_members').upsert({
        'organization_id': organizationId,
        'user_id': userId,
        'role': role,
        'joined_at': DateTime.now().toIso8601String(),
      }, onConflict: 'organization_id, user_id');

    } catch (e) {

      rethrow;
    }
  }

  Future<void> updateMemberRole({
    required String memberId,
    required String role,
  }) async {

    try {
      await _client
          .from('organization_members')
          .update({'role': role})
          .eq('id', memberId);

    } catch (e) {

      rethrow;
    }
  }

  Future<void> removeMember(String memberId) async {

    try {
      await _client.from('organization_members').delete().eq('id', memberId);

    } catch (e) {

      rethrow;
    }
  }
}
