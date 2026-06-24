import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants.dart';

class CallService {
  WebSocketChannel? _channel;
  int? _targetId;
  int? _roomId;

  Function(Map<String, dynamic>)? onCallReceived;
  Function()?                     onCallAccepted;
  Function()?                     onCallRejected;
  Function()?                     onCallEnded;
  Function(dynamic)?              onLocalStream;
  Function(dynamic)?              onRemoteStream;

  void connect(int userId, {String? token}) {
    try {
      final uri = Uri.parse('$WS_URL/ws/call/$userId/').replace(
        queryParameters: {
          if (token != null && token.isNotEmpty) 'token': token,
        },
      );
      debugPrint('Call WS connecting: $uri');
      _channel = WebSocketChannel.connect(uri);
      _channel!.ready.then((_) {
        debugPrint('Call WS connected');
        _channel!.stream.listen(
          (data) {
            try {
              _handleMessage(
                  Map<String, dynamic>.from(jsonDecode(data)));
            } catch (e) {
              debugPrint('Call WS decode error: $e');
            }
          },
          onError: (e) => debugPrint('Call WS error: $e'),
          onDone:  () => debugPrint('Call WS done'),
        );
      }).catchError((e) => debugPrint('Call WS failed: $e'));
    } catch (e) {
      debugPrint('Call WS exception: $e');
    }
  }

  void _handleMessage(Map<String, dynamic> msg) {
    switch (msg['type']) {
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

  void _send(Map<String, dynamic> data) {
    try { _channel?.sink.add(jsonEncode(data)); }
    catch (e) { debugPrint('Call send error: $e'); }
  }

  void callUser({
    required int    callerId,
    required String callerName,
    required int    targetId,
    required int    roomId,
    bool video = false,
  }) {
    _targetId = targetId;
    _roomId   = roomId;
    _send({
      'type':        'call_user',
      'caller_id':   callerId,
      'caller_name': callerName,
      'target_id':   targetId,
      'room_id':     roomId,
      'call_type':   video ? 'video' : 'audio',
    });
  }

  void acceptCall(int targetId, int roomId, {bool video = false}) {
    _targetId = targetId;
    _roomId   = roomId;
    _send({
      'type':      'call_accepted',
      'target_id': targetId,
      'room_id':   roomId,
    });
  }

  void rejectCall(int targetId, int roomId) => _send({
        'type':      'call_rejected',
        'target_id': targetId,
        'room_id':   roomId,
      });

  void endCall(int targetId, int roomId) {
    _send({
      'type':      'call_ended',
      'target_id': targetId,
      'room_id':   roomId,
    });
    _targetId = null;
    _roomId   = null;
  }

  void toggleMute(bool muted) {}
  void toggleCamera(bool off) {}
  Future<void> switchCamera() async {}

  void disconnect() {
    try { _channel?.sink.close(); } catch (_) {}
  }
}