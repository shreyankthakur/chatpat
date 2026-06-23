import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../services/call_service.dart';
import '../services/notification_service.dart';
import '../models/message.dart';
import 'call_screen.dart';
import 'incoming_call_screen.dart';

class ChatScreen extends StatefulWidget {
  final int roomId;
  final Map<String, dynamic> otherUser;
  final CallService callService;

  const ChatScreen({
    super.key,
    required this.roomId,
    required this.otherUser,
    required this.callService,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _ws = WebSocketService();

  List<MessageModel> _msgs = [];
  bool _wsReady = false;

  static const _purple = Color(0xFF7C4DFF);
  static const _purpleDark = Color(0xFF512DA8);
  static const _bgChat = Color(0xFFF0EEF9);

  CallService get _callService => widget.callService;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _connectWS();
    _setupCallCallbacks();
  }

  void _setupCallCallbacks() {
    _callService.onCallReceived = (data) => _handleIncomingCall(data);
  }

  void _handleIncomingCall(Map data) {
    if (!mounted) return;
    final me = context.read<AuthProvider>().user;
    if (me == null) return;
    final callerName = data['caller_name']?.toString() ?? 'Someone';
    final isVideo = data['call_type'] == 'video';

    NotificationService.showCallNotification(
        callerName: callerName, isVideo: isVideo);

    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IncomingCallScreen(
            callData: data,
            myId: me.id,
            callService: _callService,
          ),
        )).then((_) => NotificationService.cancelCallNotification());
  }

  void _startCall({required bool video}) {
    final me = context.read<AuthProvider>().user;
    if (me == null) return;

    _callService.callUser(
      callerId: me.id,
      callerName: me.username,
      targetId: widget.otherUser['id'],
      roomId: widget.roomId,
      video: video,
    );

    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(
            myId: me.id,
            otherId: widget.otherUser['id'],
            roomId: widget.roomId,
            otherName: widget.otherUser['username'] ?? 'User',
            isVideo: video,
            isCaller: true,
            callService: _callService,
          ),
        ));
  }

  void _connectWS() {
    try {
      final token = context.read<AuthProvider>().token;
      final me = context.read<AuthProvider>().user;
      _ws.connect(widget.roomId, token: token);
      _ws.onMessage = (data) {
        if (!mounted) return;
        try {
          final msg = MessageModel.fromJson(Map<String, dynamic>.from(data));
          if (!mounted) return;
          setState(() => _msgs.add(msg));
          _scrollDown();
          if (me != null && msg.senderId != me.id) {
            NotificationService.showMessageNotification(
              senderName: widget.otherUser['username']?.toString() ?? 'Someone',
              message: msg.content,
            );
          }
        } catch (e) {
          debugPrint('Chat WS onMessage error: $e');
        }
      };
      setState(() => _wsReady = true);
    } catch (e) {
      debugPrint('WebSocket error: $e');
      _startPolling();
    }
  }

  Timer? _pollTimer;
  bool _loadingMessages = false;

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (t) async {
      if (!mounted || _loadingMessages) return;
      _loadingMessages = true;
      try {
        await _loadMessages();
      } catch (e) {
        debugPrint('Polling load messages error: $e');
      } finally {
        _loadingMessages = false;
      }
    });
  }

  @override
  void dispose() {
    try {
      _pollTimer?.cancel();
    } catch (_) {}
    _ws.disconnect();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) return;
      final data = await ApiService.getMessages(token, widget.roomId);
      if (!mounted) return;
      setState(() {
        _msgs = data
            .map((m) => MessageModel.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      });
      _scrollDown();
    } catch (e) {
      debugPrint('Load messages error: $e');
    }
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final me = context.read<AuthProvider>().user;
    if (me == null) return;
    _ctrl.clear();

    try {
      if (_wsReady) {
        _ws.sendMessage(me.id, text);
        await _loadMessages();
        if (_msgs.isEmpty ||
            !_msgs.any((m) => m.senderId == me.id && m.content == text)) {
          final token = context.read<AuthProvider>().token!;
          await ApiService.sendMessage(token, widget.roomId, text);
          await _loadMessages();
        }
      } else {
        final token = context.read<AuthProvider>().token!;
        await ApiService.sendMessage(token, widget.roomId, text);
        await _loadMessages();
      }
    } catch (e) {
      debugPrint('Send error: $e');
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        await ApiService.sendMessage(token, widget.roomId, text);
        await _loadMessages();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().user;
    final username = widget.otherUser['username']?.toString() ?? 'User';
    final isOnline = widget.otherUser['is_online'] == true;

    return Scaffold(
      backgroundColor: _bgChat,
      appBar: AppBar(
        backgroundColor: _purple,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleSpacing: 0,
        title: Row(children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            child: Text(
              username.isNotEmpty ? username[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(username,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              Text(
                isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  color:
                      isOnline ? Colors.greenAccent.shade100 : Colors.white54,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_rounded, color: Colors.white),
            onPressed: () => _startCall(video: false),
          ),
          IconButton(
            icon: const Icon(Icons.videocam_rounded, color: Colors.white),
            onPressed: () => _startCall(video: true),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Column(children: [
        // Messages
        Expanded(
          child: _msgs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: _purple.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chat_bubble_outline_rounded,
                            size: 36, color: _purple),
                      ),
                      const SizedBox(height: 16),
                      const Text('No messages yet',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E))),
                      const SizedBox(height: 6),
                      const Text('Say hello! 👋',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scroll,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  itemCount: _msgs.length,
                  itemBuilder: (ctx, i) {
                    final msg = _msgs[i];
                    final isMe = me != null && msg.senderId == me.id;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? _purple : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(msg.content,
                                style: TextStyle(
                                    fontSize: 15,
                                    color: isMe
                                        ? Colors.white
                                        : const Color(0xFF1A1A2E))),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatTime(msg.timestamp),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color:
                                        isMe ? Colors.white60 : Colors.black38,
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    msg.isRead
                                        ? Icons.done_all_rounded
                                        : Icons.done_rounded,
                                    size: 14,
                                    color: msg.isRead
                                        ? Colors.lightBlueAccent
                                        : Colors.white60,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Input bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _ctrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Write a message...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_purple, _purpleDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  String _formatTime(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return '';
    }
  }
}
