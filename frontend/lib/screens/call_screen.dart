import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/call_service.dart';

class CallScreen extends StatefulWidget {
  final int         myId;
  final int         otherId;
  final int         roomId;
  final String      otherName;
  final bool        isVideo;
  final bool        isCaller;
  final CallService callService;

  const CallScreen({
    super.key,
    required this.myId,
    required this.otherId,
    required this.roomId,
    required this.otherName,
    required this.isVideo,
    required this.isCaller,
    required this.callService,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final _localRenderer  = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();

  bool   _muted     = false;
  bool   _speakerOn = true;
  bool   _cameraOff = false;
  String _status    = 'Calling...';
  int    _seconds   = 0;

  static const _purple     = Color(0xFF7C4DFF);
  static const _purpleDark = Color(0xFF512DA8);

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) _initRenderers();
    _setupCallbacks();
    if (widget.isCaller) {
      setState(() => _status = 'Ringing...');
    } else {
      setState(() => _status = 'Connected');
      _startTimer();
    }
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    widget.callService.onLocalStream = (stream) {
      if (mounted) setState(() => _localRenderer.srcObject = stream);
    };
    widget.callService.onRemoteStream = (stream) {
      if (mounted) setState(() => _remoteRenderer.srcObject = stream);
    };
  }

  @override
  void dispose() {
    if (widget.isVideo) {
      _localRenderer.dispose();
      _remoteRenderer.dispose();
    }
    super.dispose();
  }

  void _setupCallbacks() {
    widget.callService.onCallAccepted = () {
      if (mounted) {
        setState(() => _status = 'Connected');
        _startTimer();
      }
    };
    widget.callService.onCallRejected = () {
      if (mounted) {
        setState(() => _status = 'Call Rejected');
        Future.delayed(
            const Duration(seconds: 2), () => Navigator.pop(context));
      }
    };
    widget.callService.onCallEnded = () {
      if (mounted) Navigator.pop(context);
    };
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _seconds++);
      return _status == 'Connected';
    });
  }

  String _formatDuration() {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _endCall() {
    widget.callService.endCall(widget.otherId, widget.roomId);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: widget.isVideo ? _buildVideoCall() : _buildVoiceCall(),
    );
  }

  Widget _buildVideoCall() {
    return Stack(
      children: [
        Positioned.fill(
          child: RTCVideoView(
            _remoteRenderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),
        ),
        Positioned(
          top: 50, right: 16,
          width: 100, height: 140,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: RTCVideoView(
              _localRenderer,
              mirror: true,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          ),
        ),
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Text(widget.otherName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Text(
                  _status == 'Connected' ? _formatDuration() : _status,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ]),
            ),
          ),
        ),
        Positioned(
          bottom: 40, left: 0, right: 0,
          child: _buildControls(isVideo: true),
        ),
      ],
    );
  }

  Widget _buildVoiceCall() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), _purpleDark],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            // Avatar with pulse ring
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 160, height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _purple.withOpacity(0.3), width: 12),
                  ),
                ),
                Container(
                  width: 130, height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _purple.withOpacity(0.5), width: 6),
                  ),
                ),
                CircleAvatar(
                  radius: 52,
                  backgroundColor: _purple,
                  child: Text(
                    widget.otherName.isNotEmpty
                        ? widget.otherName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        fontSize: 44, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(widget.otherName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              _status == 'Connected' ? _formatDuration() : _status,
              style: const TextStyle(color: Colors.white60, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.call, color: Colors.white54, size: 14),
                  const SizedBox(width: 4),
                  const Text('Voice Call',
                      style:
                          TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const Spacer(),
            _buildControls(isVideo: false),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildControls({required bool isVideo}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _btn(
          icon:  _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
          label: _muted ? 'Unmute' : 'Mute',
          color: _muted ? Colors.white : Colors.white,
          bg:    _muted ? Colors.red.withOpacity(0.8) : Colors.white24,
          onTap: () {
            setState(() => _muted = !_muted);
            widget.callService.toggleMute(_muted);
          },
        ),
        _btn(
          icon:  Icons.call_end_rounded,
          label: 'End',
          color: Colors.white,
          bg:    Colors.red,
          onTap: _endCall,
          size:  68,
        ),
        if (isVideo)
          _btn(
            icon:  _cameraOff
                ? Icons.videocam_off_rounded
                : Icons.videocam_rounded,
            label: _cameraOff ? 'Cam Off' : 'Cam On',
            color: Colors.white,
            bg: _cameraOff
                ? Colors.red.withOpacity(0.8)
                : Colors.white24,
            onTap: () {
              setState(() => _cameraOff = !_cameraOff);
              widget.callService.toggleCamera(_cameraOff);
            },
          )
        else
          _btn(
            icon:  _speakerOn
                ? Icons.volume_up_rounded
                : Icons.volume_off_rounded,
            label: _speakerOn ? 'Speaker' : 'Earpiece',
            color: Colors.white,
            bg:    Colors.white24,
            onTap: () => setState(() => _speakerOn = !_speakerOn),
          ),
      ],
    );
  }

  Widget _btn({
    required IconData     icon,
    required String       label,
    required Color        color,
    required Color        bg,
    required VoidCallback onTap,
    double size = 56,
  }) =>
      Column(children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size, height: size,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: size * 0.44),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ]);
}