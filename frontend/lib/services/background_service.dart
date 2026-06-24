import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

const String _wsTokenKey = 'ws_token';
const String _wsUserKey  = 'ws_call_user_id';
const String _lastMsgKey = 'last_msg_id';
const String _baseUrl    = 'https://chatpat-production.up.railway.app';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  final notifications = FlutterLocalNotificationsPlugin();
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  await notifications
      .initialize(const InitializationSettings(android: android));

  Future<void> pollMessages() async {
    try {
      final prefs    = await SharedPreferences.getInstance();
      final token    = prefs.getString(_wsTokenKey);
      final myUserId = prefs.getInt(_wsUserKey);
      if (token == null || myUserId == null) return;

      final res = await http.get(
        Uri.parse('$_baseUrl/api/chat/rooms/'),
        headers: {'Authorization': 'Token $token'},
      );
      if (res.statusCode != 200) return;

      final rooms = jsonDecode(res.body) as List;
      for (final room in rooms) {
        final roomId  = room['id'] as int;
        final lastMsg = room['last_message'];
        if (lastMsg == null) continue;

        final lastMsgId     = lastMsg['id'] as int;
        final lastMsgSender = lastMsg['sender_id'] ?? 0;
        final storedKey     = '${_lastMsgKey}_$roomId';
        final storedLastId  = prefs.getInt(storedKey) ?? 0;

        if (lastMsgId > storedLastId && lastMsgSender != myUserId) {
          final participants = room['participants'] as List;
          final sender = participants.firstWhere(
            (p) => p['id'] == lastMsgSender,
            orElse: () => {'username': 'Someone'},
          );
          await notifications.show(
            roomId,
            sender['username']?.toString() ?? 'Someone',
            lastMsg['content']?.toString() ?? '',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'messages', 'Messages',
                channelDescription: 'New message notifications',
                importance: Importance.high,
                priority:   Priority.high,
                playSound:  true,
              ),
            ),
          );
        }
        if (lastMsgId > storedLastId) {
          await prefs.setInt(storedKey, lastMsgId);
        }
      }
    } catch (e) {
      // silently ignore
    }
  }

  await pollMessages();
  Timer.periodic(const Duration(seconds: 30), (_) async {
    await pollMessages();
  });

  service.on('stop').listen((_) => service.stopSelf());

  service.on('update_credentials').listen((data) async {
    if (data == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_wsUserKey,     data['user_id'] as int);
    await prefs.setString(_wsTokenKey, data['token']   as String);
    await pollMessages();
  });
}

class BackgroundService {
  static final _service = FlutterBackgroundService();

  static Future<void> init() async {
    if (kIsWeb) return;
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart:                         onStart,
        autoStart:                       true,
        isForegroundMode:                true,
        notificationChannelId:           'chatpat_bg',
        initialNotificationTitle:        'chatpat',
        initialNotificationContent:      'Running...',
        foregroundServiceNotificationId: 99,
      ),
      iosConfiguration: IosConfiguration(autoStart: false),
    );
    await _service.startService();
  }

  static Future<void> updateCredentials({
    required int    userId,
    required String token,
  }) async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_wsUserKey,     userId);
    await prefs.setString(_wsTokenKey, token);
    _service.invoke('update_credentials', {
      'user_id': userId,
      'token':   token,
    });
  }

  static void stop() {
    if (kIsWeb) return;
    _service.invoke('stop');
  }
}