import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants.dart';

class CallService {
  WebSocketChannel?   _channel;
  RTCPeerConnection?  _peerConnection;
  MediaStream?        _localStream;

  Function(Map)?  onCallReceived;
  Function()?     onCallAccepted;
  Function()?     onCallRejected;
  Function()?     onCallEnded;

  // ── WebSocket ──────────────────────────────────────────
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
        debugPrint('Call WS connected (user: $userId)');
        _channel!.stream.listen(
          (data) => _handleMessage(jsonDecode(data)),
          onError: (e) => debugPrint('Call WS stream error (user: $userId): $e'),
          onDone:  ()  => debugPrint('Call WS stream done (user: $userId)'),
        );
      }).catchError((e) {
        debugPrint('Call WS connect failed/timeout (user: $userId): $e');
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
        _createOffer(msg['room_id']);
        break;
      case 'call_rejected':
        onCallRejected?.call();
        break;
      case 'call_ended':
        onCallEnded?.call();
        _cleanup();
        break;
      case 'call_offer':
        _handleOffer(msg['data'], msg['room_id']);
        break;
      case 'call_answer':
        _handleAnswer(msg['data']);
        break;
      case 'call_ice':
        _handleIceCandidate(msg['data']);
        break;
    }
  }

  void _send(Map data) {
    try {
      _channel?.sink.add(jsonEncode(data));
    } catch (e) {
      debugPrint('Send error: $e');
    }
  }

  // ── Signaling ──────────────────────────────────────────
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

  void acceptCall(int targetId, int roomId) {
    _send({
      'type':      'call_accepted',
      'target_id': targetId,
      'room_id':   roomId,
    });
    _initPeerConnection(targetId, roomId, isCaller: false);
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
    _cleanup();
  }

  void toggleMute(bool muted) {
    _localStream?.getAudioTracks().forEach((t) => t.enabled = !muted);
    debugPrint('Mute: $muted');
  }

  // ── WebRTC ─────────────────────────────────────────────
  Future<void> initCaller(int targetId, int roomId) async {
    await _initPeerConnection(targetId, roomId, isCaller: true);
  }

  Future<void> _initPeerConnection(
      int targetId, int roomId, {required bool isCaller}) async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ]
    };

    _peerConnection = await createPeerConnection(config);

    // Get microphone
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });

    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    // ICE candidates
    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        _send({
          'type':      'ice_candidate',
          'target_id': targetId,
          'room_id':   roomId,
          'data': {
            'candidate':     candidate.candidate,
            'sdpMid':        candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        });
      }
    };

    _peerConnection!.onConnectionState = (state) {
      debugPrint('PeerConnection state: $state');
    };

    if (isCaller) {
      await _createOffer(roomId, targetId: targetId);
    }
  }

  Future<void> _createOffer(dynamic roomId, {int? targetId}) async {
    if (_peerConnection == null) return;
    final offer = await _peerConnection!.createOffer({'offerToReceiveAudio': 1});
    await _peerConnection!.setLocalDescription(offer);
    _send({
      'type':      'offer',
      'target_id': targetId,
      'room_id':   roomId,
      'data': {
        'sdp':  offer.sdp,
        'type': offer.type,
      },
    });
  }

  Future<void> _handleOffer(Map data, dynamic roomId) async {
    if (_peerConnection == null) return;
    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(data['sdp'], data['type']),
    );
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    _send({
      'type':    'answer',
      'room_id': roomId,
      'data': {
        'sdp':  answer.sdp,
        'type': answer.type,
      },
    });
  }

  Future<void> _handleAnswer(Map data) async {
    await _peerConnection?.setRemoteDescription(
      RTCSessionDescription(data['sdp'], data['type']),
    );
  }

  Future<void> _handleIceCandidate(Map data) async {
    await _peerConnection?.addCandidate(
      RTCIceCandidate(
        data['candidate'],
        data['sdpMid'],
        data['sdpMLineIndex'],
      ),
    );
  }

  Future<void> _cleanup() async {
    await _localStream?.dispose();
    await _peerConnection?.close();
    _localStream      = null;
    _peerConnection   = null;
  }

  void disconnect() {
    _cleanup();
    _channel?.sink.close();
  }
}