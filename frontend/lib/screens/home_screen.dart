import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/call_service.dart';
import '../services/notification_service.dart';
import '../widgets/micro_interactions.dart';

import 'call_screen.dart';
import 'chat_screen.dart';
import 'contacts_screen.dart';
import 'incoming_call_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List rooms = [];
  final _callService = CallService();

  @override
  void initState() {
    super.initState();
    _loadRooms();
    _initCallService();
  }

  void _initCallService() {
    final auth = context.read<AuthProvider>();
    final me = auth.user;
    if (me == null) return;

    _callService.connect(me.id, token: auth.token);
    _callService.onCallReceived = (data) => _handleIncomingCall(data);
  }

  void _handleIncomingCall(Map data) {
    if (!mounted) return;
    final me = context.read<AuthProvider>().user;
    if (me == null) return;

    final callerName = data['caller_name']?.toString() ?? 'Someone';
    final isVideo = data['call_type'] == 'video';

    NotificationService.showCallNotification(
      callerName: callerName,
      isVideo: isVideo,
    );

    Navigator.push(
      context,
      FadeSlidePageRoute(
        page: IncomingCallScreen(
          callData: data,
          myId: me.id,
          callService: _callService,
        ),
      ),
    ).then((_) {
      NotificationService.cancelCallNotification();
    });
  }

  @override
  void dispose() {
    _callService.disconnect();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    final token = context.read<AuthProvider>().token!;
    final data = await ApiService.getRooms(token);
    setState(() => rooms = data);
  }

  @override
  Widget build(BuildContext context) {
    final me = context.read<AuthProvider>().user!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB71C1C),
        title: const Text(
          'chatpat',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: rooms.isEmpty
          ? const Center(
              child: Text(
                'No chats yet.\nTap + to start one!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: rooms.length,
              itemBuilder: (ctx, i) {
                final room = rooms[i];
                final others = (room['participants'] as List)
                    .where((p) => p['id'] != me.id)
                    .toList();

                final other = others.isNotEmpty
                    ? others.first
                    : room['participants'].first;

                final lastMsg = room['last_message'];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF25D366),
                    child: Text(
                      other['username'][0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    other['username'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    lastMsg != null ? lastMsg['content'] : 'No messages',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    FadeSlidePageRoute(
                      page: ChatScreen(
                        roomId: room['id'],
                        otherUser: other,
                        callService: _callService,
                      ),
                    ),
                  ).then((_) => _loadRooms()),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF25D366),
        child: const Icon(Icons.chat, color: Colors.white),
        onPressed: () => Navigator.push(
          context,
          FadeSlidePageRoute(
            page: ContactsScreen(callService: _callService),
          ),
        ).then((_) => _loadRooms()),
      ),
    );
  }
}
