
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service managing persistent/sticky quick notifications that stay in the
/// notification drawer (ongoing: true, autoCancel: false) until the user
/// explicitly taps or acknowledges them.
class StickyNotificationService {
  static final StickyNotificationService _instance =
      StickyNotificationService._internal();
  factory StickyNotificationService() => _instance;
  StickyNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _notificationsPlugin.initialize(settings: initSettings);
    _initialized = true;

  }

  /// Displays an ongoing/sticky quick notification that cannot be cleared
  /// with 'Clear All' until the user performs an action.
  Future<void> showStickyNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();

    const androidDetails = AndroidNotificationDetails(
      'dev_collab_sticky_channel',
      'DevCollab Ongoing Actions',
      channelDescription:
          'Persistent notifications for quick collaboration & active tasks',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true, // Prevents removal on 'Clear All'
      autoCancel: false, // Keeps notification active until explicitly dismissed
      showWhen: true,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );

  }

  /// Dismisses or acknowledges the sticky notification after user action.
  Future<void> dismissStickyNotification(int id) async {
    await init();
    await _notificationsPlugin.cancel(id: id);

  }
}
