import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/task.dart';

class TaskRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Task>> getTasks(String projectId) async {
    final response = await _client
        .from('tasks')
        .select(
          '*, assignee:profiles!tasks_assignee_id_fkey(full_name, avatar_url), '
          'creator:profiles!tasks_created_by_fkey(full_name)',
        )
        .eq('project_id', projectId)
        .order('position');

    return response.map<Task>((json) => Task.fromJson(json)).toList();
  }

  Future<Task> getTaskById(String id) async {
    final response = await _client
        .from('tasks')
        .select(
          '*, assignee:profiles!tasks_assignee_id_fkey(full_name, avatar_url), '
          'creator:profiles!tasks_created_by_fkey(full_name)',
        )
        .eq('id', id)
        .single();
    return Task.fromJson(response);
  }

  Future<Task> createTask({
    required String organizationId,
    required String projectId,
    required String title,
    String? description,
    String status = 'todo',
    String priority = 'medium',
    String? assigneeId,
    DateTime? dueDate,
    int position = 0,
  }) async {
    final user = _client.auth.currentUser!;
    final now = DateTime.now().toIso8601String();

    final response = await _client
        .from('tasks')
        .insert({
          'organization_id': organizationId,
          'project_id': projectId,
          'title': title,
          'description': description,
          'status': status,
          'priority': priority,
          'assignee_id': assigneeId,
          'created_by': user.id,
          'due_date': dueDate?.toIso8601String(),
          'position': position,
          'created_at': now,
          'updated_at': now,
        })
        .select(
          '*, assignee:profiles!tasks_assignee_id_fkey(full_name, avatar_url), '
          'creator:profiles!tasks_created_by_fkey(full_name)',
        )
        .single();

    return Task.fromJson(response);
  }

  Future<void> updateTask(
    String id, {
    String? title,
    String? description,
    String? status,
    String? priority,
    String? assigneeId,
    DateTime? dueDate,
    int? position,
  }) async {
    final updates = <String, dynamic>{'updated_at': DateTime.now().toIso8601String()};
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (status != null) updates['status'] = status;
    if (priority != null) updates['priority'] = priority;
    if (assigneeId != null) updates['assignee_id'] = assigneeId;
    if (dueDate != null) updates['due_date'] = dueDate.toIso8601String();
    if (position != null) updates['position'] = position;
    await _client.from('tasks').update(updates).eq('id', id);
  }

  Future<void> deleteTask(String id) async {
    await _client.from('tasks').delete().eq('id', id);
  }

  /// Realtime stream of tasks for a project
  Stream<List<Map<String, dynamic>>> watchTasks(String projectId) {
    return _client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('project_id', projectId)
        .order('position');
  }
}
