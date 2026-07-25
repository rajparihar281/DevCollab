import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/activity_log.dart';

class ActivityLogRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<ActivityLog>> getLogs(String organizationId, {int limit = 50}) async {
    final response = await _client
        .from('activity_logs')
        .select('*, profiles(full_name, avatar_url)')
        .eq('organization_id', organizationId)
        .order('created_at', ascending: false)
        .limit(limit);

    return response
        .map<ActivityLog>((json) => ActivityLog.fromJson(json))
        .toList();
  }

  Future<void> log({
    required String organizationId,
    required String entityType,
    required String entityId,
    required String action,
    Map<String, dynamic>? metadata,
  }) async {
    final user = _client.auth.currentUser!;
    await _client.from('activity_logs').insert({
      'organization_id': organizationId,
      'user_id': user.id,
      'entity_type': entityType,
      'entity_id': entityId,
      'action': action,
      'metadata': metadata,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
