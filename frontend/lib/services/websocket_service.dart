import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  Function(Map)? onMessage;

  void connect(int roomId, {String? token}) {
    try {
      final uri = Uri.parse('$WS_URL/ws/chat/$roomId/').replace(
        queryParameters: {
          if (token != null && token.isNotEmpty) 'token': token,
        },
      );
      debugPrint('WS connecting: $uri');
      _channel = WebSocketChannel.connect(uri);
      _channel!.ready.then((_) {
        debugPrint('WS connected room: $roomId');
      }).catchError((e) => debugPrint('WS connect failed: $e'));
      _channel!.stream.listen(
        (data) {
          try {
            final decoded = jsonDecode(data);
            if (decoded is Map) {
              onMessage?.call(Map<String, dynamic>.from(decoded));
            }
          } catch (e) {
            debugPrint('WS decode error: $e');
          }
        },
        onError: (e) => debugPrint('WS stream error: $e'),
        onDone:  () => debugPrint('WS stream done'),
      );
    } catch (e) {
      debugPrint('WS exception: $e');
    }
  }

  void sendMessage(int userId, String content) {
    try {
      _channel?.sink
          .add(jsonEncode({'user_id': userId, 'content': content}));
    } catch (e) {
      debugPrint('WS send error: $e');
    }
  }

  void disconnect() {
    try {
      _channel?.sink.close();
    } catch (_) {}
  }
}