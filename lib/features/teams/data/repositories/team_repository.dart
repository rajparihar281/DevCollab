import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/team.dart';
import '../../domain/models/team_member.dart';

class TeamRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Team>> getTeams(String organizationId) async {

    try {
      final response = await _client
          .from('teams')
          .select()
          .eq('organization_id', organizationId)
          .order('created_at');

      final teams = response.map<Team>((json) => Team.fromJson(json)).toList();

      return teams;
    } catch (e) {

      rethrow;
    }
  }

  Future<Team> getTeamById(String id) async {

    try {
      final response =
          await _client.from('teams').select().eq('id', id).single();
      return Team.fromJson(response);
    } catch (e) {

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


      // Auto-add creator as team member (upsert avoids duplicate key conflict)
      await _client.from('team_members').upsert({
        'team_id': team.id,
        'user_id': user.id,
        'joined_at': now,
      }, onConflict: 'team_id, user_id');


      return team;
    } catch (e) {

      rethrow;
    }
  }

  Future<void> updateTeam(String id, {String? name, String? description}) async {

    try {
      final updates = <String, dynamic>{'updated_at': DateTime.now().toIso8601String()};
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      await _client.from('teams').update(updates).eq('id', id);

    } catch (e) {

      rethrow;
    }
  }

  Future<void> deleteTeam(String id) async {

    try {
      await _client.from('teams').delete().eq('id', id);

    } catch (e) {

      rethrow;
    }
  }

  Future<List<TeamMember>> getTeamMembers(String teamId) async {

    try {
      final response = await _client
          .from('team_members')
          .select('*, profiles(full_name, avatar_url)')
          .eq('team_id', teamId)
          .order('joined_at');
      final members = response.map<TeamMember>((json) => TeamMember.fromJson(json)).toList();

      return members;
    } catch (e) {

      rethrow;
    }
  }

  Future<void> addTeamMember({
    required String teamId,
    required String userId,
  }) async {

    try {
      await _client.from('team_members').upsert({
        'team_id': teamId,
        'user_id': userId,
        'joined_at': DateTime.now().toIso8601String(),
      }, onConflict: 'team_id, user_id');

    } catch (e) {

      rethrow;
    }
  }

  Future<void> removeTeamMember(String memberId) async {

    try {
      await _client.from('team_members').delete().eq('id', memberId);

    } catch (e) {

      rethrow;
    }
  }
}
