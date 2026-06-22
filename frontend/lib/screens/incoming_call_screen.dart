import 'package:flutter/material.dart';
import '../services/call_service.dart';
import 'call_screen.dart';

class IncomingCallScreen extends StatelessWidget {
  final Map         callData;
  final int         myId;
  final CallService callService;

  const IncomingCallScreen({
    super.key,
    required this.callData,
    required this.myId,
    required this.callService,
  });

  @override
  Widget build(BuildContext context) {
    final callerName = callData['caller_name']?.toString() ?? 'Unknown';
    final isVideo    = callData['call_type'] == 'video';
    final roomId     = callData['room_id'] as int;
    final callerId   = callData['caller_id'] as int;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 3),
              ),
              child: CircleAvatar(
                radius: 70,
                backgroundColor: const Color(0xFFB71C1C),
                child: Text(
                  callerName.isNotEmpty
                      ? callerName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      fontSize: 55, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(callerName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              isVideo
                  ? 'Incoming Video Call...'
                  : 'Incoming Voice Call...',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Icon(
              isVideo ? Icons.videocam : Icons.phone_in_talk,
              color: Colors.white38, size: 28,
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Decline
                  Column(children: [
                    GestureDetector(
                      onTap: () {
                        callService.rejectCall(callerId, roomId);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 72, height: 72,
                        decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle),
                        child: const Icon(Icons.call_end,
                            color: Colors.white, size: 36),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Decline',
                        style: TextStyle(color: Colors.white70)),
                  ]),

                  // Accept
                  Column(children: [
                    GestureDetector(
                      onTap: () {
                        callService.acceptCall(
                          callerId,
                          roomId,
                          video: isVideo, // ← pass video flag
                        );
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CallScreen(
                              myId:        myId,
                              otherId:     callerId,
                              roomId:      roomId,
                              otherName:   callerName,
                              isVideo:     isVideo,
                              isCaller:    false,
                              callService: callService,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 72, height: 72,
                        decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle),
                        child: Icon(
                          isVideo ? Icons.videocam : Icons.call,
                          color: Colors.white, size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Accept',
                        style: TextStyle(color: Colors.white70)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}