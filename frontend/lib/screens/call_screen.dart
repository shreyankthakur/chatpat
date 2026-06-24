import 'package:flutter/material.dart';
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
  bool   _muted     = false;
  bool   _speakerOn = true;
  String _status    = 'Calling...';
  int    _seconds   = 0;

  static const _purple     = Color(0xFF7C4DFF);
  static const _purpleDark = Color(0xFF512DA8);

  @override
  void initState() {
    super.initState();
    _setupCallbacks();
    if (!widget.isCaller) {
      setState(() => _status = 'Connected');
      _startTimer();
    } else {
      setState(() => _status = 'Ringing...');
    }
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
        Future.delayed(const Duration(seconds: 2),
            () { if (mounted) Navigator.pop(context); });
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Color(0xFF1A1A2E), _purpleDark],
              begin: Alignment.topCenter,
              end:   Alignment.bottomCenter)),
        child: SafeArea(child: Column(children: [
          const SizedBox(height: 60),
          Stack(alignment: Alignment.center, children: [
            Container(width: 160, height: 160,
              decoration: BoxDecoration(shape: BoxShape.circle,
                border: Border.all(
                    color: _purple.withValues(alpha: 0.3), width: 12))),
            Container(width: 130, height: 130,
              decoration: BoxDecoration(shape: BoxShape.circle,
                border: Border.all(
                    color: _purple.withValues(alpha: 0.5), width: 6))),
            CircleAvatar(radius: 52, backgroundColor: _purple,
              child: Text(
                widget.otherName.isNotEmpty
                    ? widget.otherName[0].toUpperCase() : '?',
                style: const TextStyle(
                    fontSize: 44, color: Colors.white))),
          ]),
          const SizedBox(height: 28),
          Text(widget.otherName,
              style: const TextStyle(color: Colors.white,
                  fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            _status == 'Connected' ? _formatDuration() : _status,
            style: const TextStyle(color: Colors.white60, fontSize: 16)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(widget.isVideo
                  ? Icons.videocam_rounded : Icons.call,
                  color: Colors.white54, size: 14),
              const SizedBox(width: 4),
              Text(widget.isVideo ? 'Video Call' : 'Voice Call',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12)),
            ]),
          ),
          const Spacer(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _btn(
              icon:  _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
              label: _muted ? 'Unmute' : 'Mute',
              bg:    _muted
                  ? Colors.red.withValues(alpha: 0.8) : Colors.white24,
              onTap: () {
                setState(() => _muted = !_muted);
                widget.callService.toggleMute(_muted);
              },
            ),
            _btn(
              icon:  Icons.call_end_rounded,
              label: 'End',
              bg:    Colors.red,
              onTap: _endCall,
              size:  68,
            ),
            _btn(
              icon: _speakerOn
                  ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              label: _speakerOn ? 'Speaker' : 'Earpiece',
              bg:    Colors.white24,
              onTap: () => setState(() => _speakerOn = !_speakerOn),
            ),
          ]),
          const SizedBox(height: 50),
        ])),
      ),
    );
  }

  Widget _btn({
    required IconData     icon,
    required String       label,
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
            child: Icon(icon, color: Colors.white, size: size * 0.44))),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                color: Colors.white54, fontSize: 11)),
      ]);
}