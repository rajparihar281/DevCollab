import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/comment.dart';

class CommentRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Comment>> getComments(String taskId) async {
    final response = await _client
        .from('comments')
        .select('*, profiles(full_name, avatar_url)')
        .eq('task_id', taskId)
        .order('created_at');
    return response.map<Comment>((json) => Comment.fromJson(json)).toList();
  }

  Future<Comment> createComment({
    required String taskId,
    required String content,
  }) async {
    final user = _client.auth.currentUser!;
    final now = DateTime.now().toIso8601String();

    final response = await _client
        .from('comments')
        .insert({
          'task_id': taskId,
          'user_id': user.id,
          'content': content,
          'created_at': now,
          'updated_at': now,
        })
        .select('*, profiles(full_name, avatar_url)')
        .single();

    return Comment.fromJson(response);
  }

  Future<void> updateComment(String id, String content) async {
    await _client.from('comments').update({
      'content': content,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> deleteComment(String id) async {
    await _client.from('comments').delete().eq('id', id);
  }

  Stream<List<Map<String, dynamic>>> watchComments(String taskId) {
    return _client
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('task_id', taskId)
        .order('created_at');
  }
}
