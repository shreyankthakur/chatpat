import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart'; // FIXED
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

const String _wsCallKey  = 'ws_call_user_id';
const String _wsTokenKey = 'ws_token';
const String _lastMsgKey = 'last_msg_id';
const String _baseUrl    = 'http://192.168.1.85:8000';

int _wsRetryCount = 0;
const int _wsMaxRetries = 10;

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  final notifications = FlutterLocalNotificationsPlugin();
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');

  await notifications.initialize(
    const InitializationSettings(android: android),
  );

  WebSocketChannel? callChannel;

  Future<void> connectCallWS() async {
    if (_wsRetryCount >= _wsMaxRetries) {
      debugPrint('WS: max retries reached, giving up.');
      return;
    }

    final prefs  = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_wsCallKey);
    final token  = prefs.getString(_wsTokenKey);
    if (userId == null || token == null) return;

    final uri = Uri.parse(
      'ws://192.168.1.85:8000/ws/call/$userId/?token=$token',
    );

    try {
      callChannel = WebSocketChannel.connect(uri);
      await callChannel!.ready;
      _wsRetryCount = 0;

      callChannel!.stream.listen(
        (data) async {
          try {
            final msg  = jsonDecode(data as String) as Map;
            final type = msg['type'];

            if (type == 'call_received') {
              final callerName = msg['caller_name']?.toString() ?? 'Someone';
              final isVideo    = msg['call_type'] == 'video';

              await notifications.show(
                2,
                isVideo ? 'Incoming Video Call' : 'Incoming Voice Call',
                '$callerName is calling...',
                const NotificationDetails(
                  android: AndroidNotificationDetails(
                    'calls', 'Calls',
                    channelDescription: 'Incoming call notifications',
                    importance:       Importance.max,
                    priority:         Priority.max,
                    fullScreenIntent: true,
                    category:         AndroidNotificationCategory.call,
                    playSound:        true,
                    ongoing:          true,
                    autoCancel:       false,
                  ),
                ),
              );
            }

            if (type == 'call_ended' || type == 'call_rejected') {
              await notifications.cancel(2);
            }

            service.invoke('call_event', msg.cast<String, dynamic>());
          } catch (e) {
            debugPrint('WS message parse error: $e');
          }
        },
        onDone: () async {
          _wsRetryCount++;
          await Future.delayed(const Duration(seconds: 5));
          await connectCallWS();
        },
        onError: (e) async {
          debugPrint('WS stream error: $e');
          _wsRetryCount++;
          await Future.delayed(const Duration(seconds: 5));
          await connectCallWS();
        },
      );
    } catch (e) {
      debugPrint('WS connect error: $e');
      _wsRetryCount++;
      await Future.delayed(const Duration(seconds: 5));
      await connectCallWS();
    }
  }

  Future<void> pollMessages() async {
    final prefs    = await SharedPreferences.getInstance();
    final token    = prefs.getString(_wsTokenKey);
    final myUserId = prefs.getInt(_wsCallKey);
    if (token == null || myUserId == null) return;

    try {
      final roomsRes = await http
          .get(
            Uri.parse('$_baseUrl/api/chat/rooms/'),
            headers: {'Authorization': 'Token $token'},
          )
          .timeout(const Duration(seconds: 10));

      if (roomsRes.statusCode != 200) {
        debugPrint('pollMessages: bad status ${roomsRes.statusCode}');
        return;
      }

      final rooms = jsonDecode(roomsRes.body) as List;

      for (final room in rooms) {
        try {
          final roomId  = room['id'] as int;
          final lastMsg = room['last_message'];
          if (lastMsg == null) continue;

          final lastMsgId     = lastMsg['id'] as int;
          final lastMsgSender = lastMsg['sender_id'] as int;
          final storedKey     = '${_lastMsgKey}_$roomId';
          final storedLastId  = prefs.getInt(storedKey) ?? 0;

          if (lastMsgId > storedLastId && lastMsgSender != myUserId) {
            final participants = room['participants'] as List;

            final sender = participants.firstWhere(
              (p) => p['id'] == lastMsgSender,
              orElse: () => {'username': 'Someone'},
            );

            final senderName = sender['username']?.toString() ?? 'Someone';
            final content    = lastMsg['content']?.toString() ?? '';

            await notifications.show(
              roomId,
              senderName,
              content,
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
        } catch (e) {
          debugPrint('pollMessages room error: $e');
        }
      }
    } catch (e) {
      debugPrint('pollMessages error: $e');
    }
  }

  await connectCallWS();
  await pollMessages();

  Timer.periodic(const Duration(seconds: 30), (_) async {
    await pollMessages();
  });

  Timer.periodic(const Duration(seconds: 30), (_) {
    try {
      callChannel?.sink.add(jsonEncode({'type': 'ping'}));
    } catch (_) {}
  });

  service.on('stop').listen((_) {
    callChannel?.sink.close();
    service.stopSelf();
  });

  service.on('update_credentials').listen((data) async {
    if (data == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_wsCallKey,     data['user_id'] as int);
      await prefs.setString(_wsTokenKey, data['token']   as String);

      _wsRetryCount = 0;
      callChannel?.sink.close();

      await connectCallWS();
      await pollMessages();
    } catch (e) {
      debugPrint('update_credentials error: $e');
    }
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
        initialNotificationContent:      'Listening for messages...',
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
    await prefs.setInt(_wsCallKey,     userId);
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

  static Stream<Map<String, dynamic>?> get callEvents =>
      _service.on('call_event');
}