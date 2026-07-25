import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/project.dart';

class ProjectRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Project>> getProjects(String teamId) async {
    final response = await _client
        .from('projects')
        .select()
        .eq('team_id', teamId)
        .order('created_at');
    return response.map<Project>((json) => Project.fromJson(json)).toList();
  }

  Future<Project> getProjectById(String id) async {
    final response =
        await _client.from('projects').select().eq('id', id).single();
    return Project.fromJson(response);
  }

  Future<Project> createProject({
    required String organizationId,
    required String teamId,
    required String name,
    String? description,
  }) async {
    final user = _client.auth.currentUser!;
    final now = DateTime.now().toIso8601String();

    final response = await _client
        .from('projects')
        .insert({
          'organization_id': organizationId,
          'team_id': teamId,
          'name': name,
          'description': description,
          'status': 'active',
          'created_by': user.id,
          'created_at': now,
          'updated_at': now,
        })
        .select()
        .single();

    return Project.fromJson(response);
  }

  Future<void> updateProject(
    String id, {
    String? name,
    String? description,
    String? status,
  }) async {
    final updates = <String, dynamic>{'updated_at': DateTime.now().toIso8601String()};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (status != null) updates['status'] = status;
    await _client.from('projects').update(updates).eq('id', id);
  }

  Future<void> deleteProject(String id) async {
    await _client.from('projects').delete().eq('id', id);
  }
}
