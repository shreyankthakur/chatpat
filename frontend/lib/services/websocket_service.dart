import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  Function(Map)? onMessage;

  void connect(int roomId, {String? token}) {
    final uri = Uri.parse('$WS_URL/ws/chat/$roomId/').replace(queryParameters: {
      if (token != null && token.isNotEmpty) 'token': token,
    });

    debugPrint('WS connect uri: $uri');

    // Ensure we attach handlers immediately for better diagnostics
    try {
      _channel = WebSocketChannel.connect(uri);
      _channel!.ready.timeout(const Duration(seconds: 10)).then((_) {
        debugPrint('WS connected (chat room: $roomId)');
      }).catchError((e) {
        debugPrint('WS connect failed/timeout (chat room: $roomId): $e');
      });

      _channel!.stream.listen(
        (data) {
          try {
            if (onMessage == null) return;
            final decoded = jsonDecode(data);
            if (decoded is Map<String, dynamic>) {
              onMessage!(decoded);
            } else if (decoded is Map) {
              onMessage!(Map<String, dynamic>.from(decoded));
            } else {
              debugPrint('WS payload not a map (chat room: $roomId): $decoded');
            }
          } catch (e) {
            debugPrint(
                'WS message decode/handler error (chat room: $roomId): $e');
          }
        },
        onError: (e) => debugPrint('WS stream error (chat room: $roomId): $e'),
        onDone: () => debugPrint('WS stream done (chat room: $roomId)'),
      );
    } catch (e) {
      debugPrint('WS exception (chat room: $roomId): $e');
    }
  }

  void sendMessage(int userId, String content) {
    _channel?.sink.add(jsonEncode({'user_id': userId, 'content': content}));
  }

  void disconnect() {
    try {
      _channel?.sink.close();
    } catch (_) {}
  }
}
