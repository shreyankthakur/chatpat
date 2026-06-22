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

  @override State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool   _muted     = false;
  bool   _speakerOn = true;
  String _status    = 'Calling...';
  int    _seconds   = 0;

  @override
  void initState() {
    super.initState();
    _setupCallbacks();
    if (widget.isCaller) {
      setState(() => _status = 'Ringing...');
    } else {
      setState(() => _status = 'Connected');
      _startTimer();
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
            () => Navigator.pop(context));
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
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),

            // Avatar
            CircleAvatar(
              radius: 70,
              backgroundColor: const Color(0xFFE53935),
              child: Text(
                widget.otherName.isNotEmpty
                    ? widget.otherName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    fontSize: 55, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),

            // Name
            Text(
              widget.otherName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Status / timer
            Text(
              _status == 'Connected'
                  ? _formatDuration()
                  : _status,
              style: const TextStyle(
                  color: Colors.white60, fontSize: 18),
            ),
            const SizedBox(height: 8),

            // Call type
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.isVideo ? Icons.videocam : Icons.call,
                  color: Colors.white38, size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.isVideo ? 'Video Call' : 'Voice Call',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 14),
                ),
              ],
            ),

            const Spacer(),

            // Controls
            Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute
                  _btn(
                    icon:  _muted ? Icons.mic_off : Icons.mic,
                    label: _muted ? 'Unmute' : 'Mute',
                    color: _muted ? Colors.grey : Colors.white,
                    bg:    Colors.white24,
                    onTap: () {
                      setState(() => _muted = !_muted);
                      widget.callService.toggleMute(_muted);
                    },
                  ),

                  // End call
                  _btn(
                    icon:  Icons.call_end,
                    label: 'End',
                    color: Colors.white,
                    bg:    Colors.red,
                    onTap: _endCall,
                    size:  72,
                  ),

                  // Speaker
                  _btn(
                    icon:  _speakerOn
                        ? Icons.volume_up
                        : Icons.volume_off,
                    label: _speakerOn ? 'Speaker' : 'Earpiece',
                    color: _speakerOn ? Colors.white : Colors.grey,
                    bg:    Colors.white24,
                    onTap: () =>
                        setState(() => _speakerOn = !_speakerOn),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn({
    required IconData     icon,
    required String       label,
    required Color        color,
    required Color        bg,
    required VoidCallback onTap,
    double size = 58,
  }) =>
      Column(children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size, height: size,
            decoration:
                BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: size * 0.45),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                color: Colors.white54, fontSize: 12)),
      ]);
}