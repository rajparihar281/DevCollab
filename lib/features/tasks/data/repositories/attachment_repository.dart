import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/attachment.dart';

class AttachmentRepository {
  final SupabaseClient _client = Supabase.instance.client;
  static const _bucket = 'attachments';

  Future<List<TaskAttachment>> getAttachments(String taskId) async {
    final response = await _client
        .from('attachments')
        .select('*, profiles(full_name)')
        .eq('task_id', taskId)
        .order('uploaded_at');
    return response
        .map<TaskAttachment>((json) => TaskAttachment.fromJson(json))
        .toList();
  }

  Future<TaskAttachment> uploadAttachment({
    required String taskId,
    required String organizationId,
    required String projectId,
    required File file,
    required String fileName,
  }) async {
    final user = _client.auth.currentUser!;
    final fileSize = await file.length();
    final storagePath =
        'organizations/$organizationId/projects/$projectId/attachments/$taskId/$fileName';

    await _client.storage.from(_bucket).upload(
          storagePath,
          file,
          fileOptions: const FileOptions(upsert: false),
        );

    final now = DateTime.now().toIso8601String();
    final response = await _client
        .from('attachments')
        .insert({
          'task_id': taskId,
          'uploaded_by': user.id,
          'file_name': fileName,
          'file_path': storagePath,
          'file_size': fileSize,
          'uploaded_at': now,
        })
        .select('*, profiles(full_name)')
        .single();

    return TaskAttachment.fromJson(response);
  }

  Future<String> getDownloadUrl(String filePath) async {
    return _client.storage.from(_bucket).getPublicUrl(filePath);
  }

  Future<void> deleteAttachment(String id, String filePath) async {
    await _client.storage.from(_bucket).remove([filePath]);
    await _client.from('attachments').delete().eq('id', id);
  }
}
