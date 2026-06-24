import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin      = FlutterLocalNotificationsPlugin();
  static bool  _initialized = false;

  static Future<void> init() async {
    if (kIsWeb || _initialized) return;
    const android  = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings,
        onDidReceiveNotificationResponse: (details) {});
    _initialized = true;
  }

  static Future<void> showMessageNotification({
    required String senderName,
    required String message,
  }) async {
    if (kIsWeb) return;
    await init();
    await _plugin.show(1, senderName, message,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'messages', 'Messages',
            channelDescription: 'New message notifications',
            importance: Importance.high,
            priority:   Priority.high,
            playSound:  true,
          ),
        ));
  }

  static Future<void> showCallNotification({
    required String callerName,
    required bool   isVideo,
  }) async {
    if (kIsWeb) return;
    await init();
    await _plugin.show(
      2,
      isVideo ? 'Incoming Video Call' : 'Incoming Voice Call',
      '$callerName is calling...',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'calls', 'Calls',
          channelDescription: 'Incoming call notifications',
          importance:       Importance.max,
          priority:         Priority.max,
          playSound:        true,
          fullScreenIntent: true,
          category:         AndroidNotificationCategory.call,
        ),
      ),
    );
  }

  static Future<void> cancelCallNotification() async {
    if (kIsWeb) return;
    await _plugin.cancel(2);
  }
}