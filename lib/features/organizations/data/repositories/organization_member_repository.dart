import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/organization_member.dart';

class OrganizationMemberRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<OrganizationMember>> getMembers(String organizationId) async {
    final response = await _client
        .from('organization_members')
        .select('*, profiles(full_name, avatar_url)')
        .eq('organization_id', organizationId)
        .order('joined_at');

    return response
        .map<OrganizationMember>((json) => OrganizationMember.fromJson(json))
        .toList();
  }

  Future<OrganizationMember?> getCurrentUserMember(String organizationId) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('organization_members')
        .select('*, profiles(full_name, avatar_url)')
        .eq('organization_id', organizationId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return OrganizationMember.fromJson(response);
  }

  Future<void> addMember({
    required String organizationId,
    required String userId,
    String role = 'member',
  }) async {
    await _client.from('organization_members').insert({
      'organization_id': organizationId,
      'user_id': userId,
      'role': role,
      'joined_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateMemberRole({
    required String memberId,
    required String role,
  }) async {
    await _client
        .from('organization_members')
        .update({'role': role})
        .eq('id', memberId);
  }

  Future<void> removeMember(String memberId) async {
    await _client.from('organization_members').delete().eq('id', memberId);
  }
}
