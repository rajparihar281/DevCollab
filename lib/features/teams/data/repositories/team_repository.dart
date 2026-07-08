import 'dart:developer' as dev;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/team.dart';
import '../../domain/models/team_member.dart';

class TeamRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Team>> getTeams(String organizationId) async {
    dev.log('[TeamRepository] Fetching teams for organization: $organizationId');
    try {
      final response = await _client
          .from('teams')
          .select()
          .eq('organization_id', organizationId)
          .order('created_at');

      final teams = response.map<Team>((json) => Team.fromJson(json)).toList();
      dev.log('[TeamRepository] Loaded ${teams.length} teams for org $organizationId');
      return teams;
    } catch (e, st) {
      dev.log('[TeamRepository] Error fetching teams for org $organizationId: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<Team> getTeamById(String id) async {
    dev.log('[TeamRepository] Fetching team by ID: $id');
    try {
      final response =
          await _client.from('teams').select().eq('id', id).single();
      return Team.fromJson(response);
    } catch (e, st) {
      dev.log('[TeamRepository] Error fetching team $id: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<Team> createTeam({
    required String organizationId,
    required String name,
    String? description,
  }) async {
    final user = _client.auth.currentUser!;
    final now = DateTime.now().toIso8601String();

    dev.log('[TeamRepository] Creating team "$name" in org $organizationId by user ${user.id}');

    try {
      final response = await _client
          .from('teams')
          .insert({
            'organization_id': organizationId,
            'name': name,
            'description': description,
            'created_at': now,
            'updated_at': now,
          })
          .select()
          .single();

      final team = Team.fromJson(response);
      dev.log('[TeamRepository] Team inserted: ID=${team.id}. Ensuring team membership via upsert...');

      // Auto-add creator as team member (upsert avoids duplicate key conflict)
      await _client.from('team_members').upsert({
        'team_id': team.id,
        'user_id': user.id,
        'joined_at': now,
      }, onConflict: 'team_id, user_id');

      dev.log('[TeamRepository] Team created and membership ensured successfully: ${team.name}');
      return team;
    } catch (e, st) {
      dev.log('[TeamRepository] ERROR creating team "$name": $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> updateTeam(String id, {String? name, String? description}) async {
    dev.log('[TeamRepository] Updating team $id');
    try {
      final updates = <String, dynamic>{'updated_at': DateTime.now().toIso8601String()};
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      await _client.from('teams').update(updates).eq('id', id);
      dev.log('[TeamRepository] Updated team $id successfully.');
    } catch (e, st) {
      dev.log('[TeamRepository] Error updating team $id: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> deleteTeam(String id) async {
    dev.log('[TeamRepository] Deleting team $id');
    try {
      await _client.from('teams').delete().eq('id', id);
      dev.log('[TeamRepository] Deleted team $id successfully.');
    } catch (e, st) {
      dev.log('[TeamRepository] Error deleting team $id: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<List<TeamMember>> getTeamMembers(String teamId) async {
    dev.log('[TeamRepository] Fetching members for team: $teamId');
    try {
      final response = await _client
          .from('team_members')
          .select('*, profiles(full_name, avatar_url)')
          .eq('team_id', teamId)
          .order('joined_at');
      final members = response.map<TeamMember>((json) => TeamMember.fromJson(json)).toList();
      dev.log('[TeamRepository] Loaded ${members.length} members for team $teamId');
      return members;
    } catch (e, st) {
      dev.log('[TeamRepository] Error fetching team members for $teamId: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> addTeamMember({
    required String teamId,
    required String userId,
  }) async {
    dev.log('[TeamRepository] Adding user $userId to team $teamId');
    try {
      await _client.from('team_members').upsert({
        'team_id': teamId,
        'user_id': userId,
        'joined_at': DateTime.now().toIso8601String(),
      }, onConflict: 'team_id, user_id');
      dev.log('[TeamRepository] Added user $userId to team $teamId successfully.');
    } catch (e, st) {
      dev.log('[TeamRepository] Error adding member $userId to team $teamId: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> removeTeamMember(String memberId) async {
    dev.log('[TeamRepository] Removing team member $memberId');
    try {
      await _client.from('team_members').delete().eq('id', memberId);
      dev.log('[TeamRepository] Removed team member $memberId successfully.');
    } catch (e, st) {
      dev.log('[TeamRepository] Error removing team member $memberId: $e', error: e, stackTrace: st);
      rethrow;
    }
  }
}
