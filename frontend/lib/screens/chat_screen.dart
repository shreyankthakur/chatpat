import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../services/call_service.dart';
import '../models/message.dart';
import 'call_screen.dart';
import 'incoming_call_screen.dart';

class ChatScreen extends StatefulWidget {
  final int                  roomId;
  final Map<String, dynamic> otherUser;
  const ChatScreen({super.key, required this.roomId, required this.otherUser});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl        = TextEditingController();
  final _scroll      = ScrollController();
  final _ws          = WebSocketService();
  final _callService = CallService();
  List<MessageModel> _msgs    = [];
  bool               _wsReady = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _connectWS();
    _initCallService();
  }

  void _initCallService() {
    final auth = context.read<AuthProvider>();
    final me   = auth.user;
    if (me == null) return;

    _callService.connect(me.id, token: auth.token);

    _callService.onCallReceived = (data) {
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => IncomingCallScreen(
          callData:    data,
          myId:        me.id,
          callService: _callService,
        ),
      ));
    };
  }

  void _startCall({required bool video}) {
    final me = context.read<AuthProvider>().user;
    if (me == null) return;

    _callService.callUser(
      callerId:   me.id,
      callerName: me.username,
      targetId:   widget.otherUser['id'],
      roomId:     widget.roomId,
      video:      video,
    );

    Navigator.push(context, MaterialPageRoute(
      builder: (_) => CallScreen(
        myId:        me.id,
        otherId:     widget.otherUser['id'],
        roomId:      widget.roomId,
        otherName:   widget.otherUser['username'] ?? 'User',
        isVideo:     video,
        isCaller:    true,
        callService: _callService,
      ),
    ));
  }

  void _connectWS() {
    try {
      final token = context.read<AuthProvider>().token;
      _ws.connect(widget.roomId, token: token);
      _ws.onMessage = (data) {
        if (!mounted) return;
        setState(() {
          _msgs.add(MessageModel.fromJson(
              Map<String, dynamic>.from(data)));
        });
        _scrollDown();
      };
      setState(() => _wsReady = true);
    } catch (e) {
      debugPrint('WebSocket error: $e');
      _startPolling();
    }
  }

  void _startPolling() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) await _loadMessages();
    }
  }

  @override
  void dispose() {
    _ws.disconnect();
    _callService.disconnect();
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
            .map((m) => MessageModel.fromJson(
                Map<String, dynamic>.from(m)))
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
            !_msgs.any(
                (m) => m.senderId == me.id && m.content == text)) {
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
    final me       = context.watch<AuthProvider>().user;
    final username = widget.otherUser['username']?.toString() ?? 'User';
    final about    = widget.otherUser['about']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB71C1C),
        iconTheme: const IconThemeData(color: Colors.white),
        titleSpacing: 0,
        title: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFE53935),
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
              if (about.isNotEmpty)
                Text(about,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11)),
            ],
          ),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: Colors.white),
            onPressed: () => _startCall(video: false),
            tooltip: 'Voice Call',
          ),
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.white),
            onPressed: () => _startCall(video: true),
            tooltip: 'Video Call',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: Container(
            color: const Color(0xFFECE5DD),
            child: _msgs.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 60, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No messages yet.\nSay hello! 👋',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 8),
                    itemCount: _msgs.length,
                    itemBuilder: (ctx, i) {
                      final msg  = _msgs[i];
                      final isMe = me != null && msg.senderId == me.id;
                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? const Color(0xFFDCF8C6)
                                : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft:     const Radius.circular(12),
                              topRight:    const Radius.circular(12),
                              bottomLeft:  Radius.circular(isMe ? 12 : 0),
                              bottomRight: Radius.circular(isMe ? 0 : 12),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black12, blurRadius: 2)
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(msg.content,
                                  style: const TextStyle(fontSize: 15)),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatTime(msg.timestamp),
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.black45),
                                  ),
                                  if (isMe) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      msg.isRead
                                          ? Icons.done_all
                                          : Icons.done,
                                      size: 14,
                                      color: msg.isRead
                                          ? Colors.blue
                                          : Colors.black45,
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
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.emoji_emotions_outlined,
                  color: Colors.grey),
              onPressed: () {},
            ),
            Expanded(
              child: TextField(
                controller: _ctrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a message',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: Color(0xFFB71C1C),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send,
                    color: Colors.white, size: 22),
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