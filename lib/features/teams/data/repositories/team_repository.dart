import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/team.dart';
import '../../domain/models/team_member.dart';

class TeamRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Team>> getTeams(String organizationId) async {
    final response = await _client
        .from('teams')
        .select()
        .eq('organization_id', organizationId)
        .order('created_at');

    return response.map<Team>((json) => Team.fromJson(json)).toList();
  }

  Future<Team> getTeamById(String id) async {
    final response =
        await _client.from('teams').select().eq('id', id).single();
    return Team.fromJson(response);
  }

  Future<Team> createTeam({
    required String organizationId,
    required String name,
    String? description,
  }) async {
    final user = _client.auth.currentUser!;
    final now = DateTime.now().toIso8601String();

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

    // Auto-add creator as team member
    await _client.from('team_members').insert({
      'team_id': team.id,
      'user_id': user.id,
      'joined_at': now,
    });

    return team;
  }

  Future<void> updateTeam(String id, {String? name, String? description}) async {
    final updates = <String, dynamic>{'updated_at': DateTime.now().toIso8601String()};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    await _client.from('teams').update(updates).eq('id', id);
  }

  Future<void> deleteTeam(String id) async {
    await _client.from('teams').delete().eq('id', id);
  }

  Future<List<TeamMember>> getTeamMembers(String teamId) async {
    final response = await _client
        .from('team_members')
        .select('*, profiles(full_name, avatar_url)')
        .eq('team_id', teamId)
        .order('joined_at');
    return response.map<TeamMember>((json) => TeamMember.fromJson(json)).toList();
  }

  Future<void> addTeamMember({
    required String teamId,
    required String userId,
  }) async {
    await _client.from('team_members').insert({
      'team_id': teamId,
      'user_id': userId,
      'joined_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeTeamMember(String memberId) async {
    await _client.from('team_members').delete().eq('id', memberId);
  }
}
