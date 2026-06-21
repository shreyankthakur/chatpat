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

    _channel = WebSocketChannel.connect(uri);

    _channel!.stream.listen((data) {
      if (onMessage != null) onMessage!(jsonDecode(data));
    });
  }

  void sendMessage(int userId, String content) {
    _channel?.sink.add(jsonEncode({'user_id': userId, 'content': content}));
  }

  void disconnect() => _channel?.sink.close();
}
