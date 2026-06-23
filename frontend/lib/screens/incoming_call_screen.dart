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

  static const _purple     = Color(0xFF7C4DFF);
  static const _purpleDark = Color(0xFF512DA8);

  @override
  Widget build(BuildContext context) {
    final callerName = callData['caller_name']?.toString() ?? 'Unknown';
    final isVideo    = callData['call_type'] == 'video';
    final roomId     = callData['room_id'] as int;
    final callerId   = callData['caller_id'] as int;

    return Scaffold(
      body: Container(
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

              // Caller type label
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                      color: Colors.white70, size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isVideo ? 'Incoming Video Call' : 'Incoming Voice Call',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Avatar with animated rings
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 170, height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: _purple.withOpacity(0.2), width: 14),
                    ),
                  ),
                  Container(
                    width: 138, height: 138,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: _purple.withOpacity(0.4), width: 7),
                    ),
                  ),
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: _purple,
                    child: Text(
                      callerName.isNotEmpty
                          ? callerName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          fontSize: 46, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Text(callerName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('is calling you...',
                  style: TextStyle(color: Colors.white60, fontSize: 16)),

              const Spacer(),

              // Action buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(48, 0, 48, 60),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.call_end_rounded,
                              color: Colors.white, size: 34),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text('Decline',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ]),

                    // Accept
                    Column(children: [
                      GestureDetector(
                        onTap: () {
                          callService.acceptCall(callerId, roomId,
                              video: isVideo);
                          Navigator.pushReplacement(context,
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
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(
                            isVideo
                                ? Icons.videocam_rounded
                                : Icons.call_rounded,
                            color: Colors.white, size: 34,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text('Accept',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}