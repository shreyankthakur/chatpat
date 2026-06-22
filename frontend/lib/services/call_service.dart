import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants.dart';

class CallService {
  WebSocketChannel? _channel;

  Function(Map)? onCallReceived;
  Function()?    onCallAccepted;
  Function()?    onCallRejected;
  Function()?    onCallEnded;

  void connect(int userId, {String? token}) {
    final uri = Uri.parse('$WS_URL/ws/call/$userId/').replace(
      queryParameters: {
        if (token != null && token.isNotEmpty) 'token': token,
      },
    );
    debugPrint('Call WS connecting: $uri');

    try {
      _channel = WebSocketChannel.connect(uri);
      _channel!.ready.then((_) {
        debugPrint('Call WS connected');
        _channel!.stream.listen(
          (data) => _handleMessage(jsonDecode(data)),
          onError: (e) => debugPrint('Call WS error: $e'),
          onDone:  ()  => debugPrint('Call WS closed'),
        );
      }).catchError((e) {
        debugPrint('Call WS connect failed: $e');
      });
    } catch (e) {
      debugPrint('Call WS exception: $e');
    }
  }

  void _handleMessage(Map msg) {
    final type = msg['type'];
    debugPrint('Call message: $type');
    switch (type) {
      case 'call_received':
        onCallReceived?.call(msg);
        break;
      case 'call_accepted':
        onCallAccepted?.call();
        break;
      case 'call_rejected':
        onCallRejected?.call();
        break;
      case 'call_ended':
        onCallEnded?.call();
        break;
    }
  }

  void callUser({
    required int    callerId,
    required String callerName,
    required int    targetId,
    required int    roomId,
    bool            video = false,
  }) {
    _send({
      'type':        'call_user',
      'caller_id':   callerId,
      'caller_name': callerName,
      'target_id':   targetId,
      'room_id':     roomId,
      'call_type':   video ? 'video' : 'audio',
    });
  }

  void acceptCall(int targetId, int roomId) => _send({
    'type':      'call_accepted',
    'target_id': targetId,
    'room_id':   roomId,
  });

  void rejectCall(int targetId, int roomId) => _send({
    'type':      'call_rejected',
    'target_id': targetId,
    'room_id':   roomId,
  });

  void endCall(int targetId, int roomId) => _send({
    'type':      'call_ended',
    'target_id': targetId,
    'room_id':   roomId,
  });

  void toggleMute(bool muted) => debugPrint('Mute: $muted');

  void _send(Map data) {
    try {
      _channel?.sink.add(jsonEncode(data));
    } catch (e) {
      debugPrint('Send error: $e');
    }
  }

  void disconnect() {
    _channel?.sink.close();
  }
}