import 'dart:developer' as dev;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/organization_member.dart';

class OrganizationMemberRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<OrganizationMember>> getMembers(String organizationId) async {
    dev.log('[OrganizationMemberRepository] Fetching members for organization: $organizationId');
    try {
      final response = await _client
          .from('organization_members')
          .select('*, profiles(full_name, avatar_url)')
          .eq('organization_id', organizationId)
          .order('joined_at');

      final members = response
          .map<OrganizationMember>((json) => OrganizationMember.fromJson(json))
          .toList();
      dev.log('[OrganizationMemberRepository] Loaded ${members.length} members for org $organizationId');
      return members;
    } catch (e, st) {
      dev.log('[OrganizationMemberRepository] Error fetching members for org $organizationId: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<OrganizationMember?> getCurrentUserMember(String organizationId) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    dev.log('[OrganizationMemberRepository] Checking membership for user ${user.id} in org $organizationId');
    try {
      final response = await _client
          .from('organization_members')
          .select('*, profiles(full_name, avatar_url)')
          .eq('organization_id', organizationId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) {
        dev.log('[OrganizationMemberRepository] No membership found for user ${user.id} in org $organizationId');
        return null;
      }
      return OrganizationMember.fromJson(response);
    } catch (e, st) {
      dev.log('[OrganizationMemberRepository] Error checking current user membership: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> addMember({
    required String organizationId,
    required String userId,
    String role = 'member',
  }) async {
    dev.log('[OrganizationMemberRepository] Adding member user=$userId to org=$organizationId with role=$role');
    try {
      await _client.from('organization_members').upsert({
        'organization_id': organizationId,
        'user_id': userId,
        'role': role,
        'joined_at': DateTime.now().toIso8601String(),
      }, onConflict: 'organization_id, user_id');
      dev.log('[OrganizationMemberRepository] Added/upserted member successfully.');
    } catch (e, st) {
      dev.log('[OrganizationMemberRepository] Error adding member user=$userId to org=$organizationId: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> updateMemberRole({
    required String memberId,
    required String role,
  }) async {
    dev.log('[OrganizationMemberRepository] Updating role of member $memberId to $role');
    try {
      await _client
          .from('organization_members')
          .update({'role': role})
          .eq('id', memberId);
      dev.log('[OrganizationMemberRepository] Updated role successfully.');
    } catch (e, st) {
      dev.log('[OrganizationMemberRepository] Error updating member role: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> removeMember(String memberId) async {
    dev.log('[OrganizationMemberRepository] Removing member $memberId');
    try {
      await _client.from('organization_members').delete().eq('id', memberId);
      dev.log('[OrganizationMemberRepository] Removed member $memberId successfully.');
    } catch (e, st) {
      dev.log('[OrganizationMemberRepository] Error removing member $memberId: $e', error: e, stackTrace: st);
      rethrow;
    }
  }
}
