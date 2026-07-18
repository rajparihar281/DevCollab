import 'package:dev_collab/features/auth/presentation/providers/auth_provider.dart';
import 'package:dev_collab/features/notifications/domain/models/notification.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final notificationsRepositoryProvider = Provider((ref) => NotificationsRepository(ref));

final notificationsStreamProvider = StreamProvider.autoDispose<List<AppNotification>>((ref) {
  final repo = ref.watch(notificationsRepositoryProvider);
  return repo.watchNotifications();
});

class NotificationsRepository {
  NotificationsRepository(this._ref);
  final Ref _ref;
  final SupabaseClient _client = Supabase.instance.client;

  String? get _currentUserId => _ref.read(authRepositoryProvider).currentUser?.id;

  Stream<List<AppNotification>> watchNotifications() {
    final userId = _currentUserId;
    if (userId == null) return Stream.value([]);

    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => AppNotification.fromJson(json)).toList());
  }

  Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<void> markAllAsRead() async {
    final userId = _currentUserId;
    if (userId == null) return;
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  Future<void> deleteNotification(String notificationId) async {
    await _client.from('notifications').delete().eq('id', notificationId);
  }

  Future<void> sendNotification({
    required String targetUserId,
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    await _client.from('notifications').insert({
      'user_id': targetUserId,
      'title': title,
      'message': message,
      'type': type,
      'related_id': ?relatedId,
    });
  }
}
