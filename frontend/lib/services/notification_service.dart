import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    const android  = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {},
    );

    // Request permission (Android 13+)
    await _plugin
        .resolvePlatformSpecificImplementation
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  static Future<void> showMessageNotification({
    required String senderName,
    required String message,
  }) async {
    await init(); // ensure initialized
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'messages',
        'Messages',
        channelDescription: 'New message notifications',
        importance: Importance.high,
        priority:   Priority.high,
        icon:       '@mipmap/ic_launcher',
        playSound:  true,
      ),
    );
    await _plugin.show(1, senderName, message, details);
  }

  static Future<void> showCallNotification({
    required String callerName,
    required bool   isVideo,
  }) async {
    await init(); // ensure initialized
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'calls',
        'Calls',
        channelDescription: 'Incoming call notifications',
        importance:       Importance.max,
        priority:         Priority.max,
        icon:             '@mipmap/ic_launcher',
        playSound:        true,
        fullScreenIntent: true,
        category:         AndroidNotificationCategory.call,
      ),
    );
    await _plugin.show(
      2,
      isVideo ? 'Incoming Video Call' : 'Incoming Voice Call',
      '$callerName is calling...',
      details,
    );
  }

  static Future<void> cancelCallNotification() async {
    await _plugin.cancel(2);
  }
}