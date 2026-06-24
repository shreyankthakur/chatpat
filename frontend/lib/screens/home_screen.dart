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
  List             rooms        = [];
  final _callService = CallService();

  static const _purple     = Color(0xFF7C4DFF);
  static const _purpleDark = Color(0xFF512DA8);
  static const _bg         = Color(0xFFF5F3FF);

  @override
  void initState() {
    super.initState();
    _loadRooms();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initCallService();
    });
  }

  void _initCallService() {
    try {
      final auth = context.read<AuthProvider>();
      if (auth.user == null) return;
      _callService.connect(auth.user!.id, token: auth.token);
      _callService.onCallReceived = _handleIncomingCall;
    } catch (e) {
      debugPrint('CallService init error: $e');
    }
  }

  void _handleIncomingCall(Map data) {
    if (!mounted) return;
    final me = context.read<AuthProvider>().user;
    if (me == null) return;
    try {
      NotificationService.showCallNotification(
        callerName: data['caller_name']?.toString() ?? 'Someone',
        isVideo:    data['call_type'] == 'video',
      );
    } catch (_) {}
    Navigator.push(context,
      FadeSlidePageRoute(
        page: IncomingCallScreen(
          callData:    data,
          myId:        me.id,
          callService: _callService,
        ),
      ),
    ).then((_) {
      try { NotificationService.cancelCallNotification(); } catch (_) {}
    });
  }

  @override
  void dispose() {
    try { _callService.disconnect(); } catch (_) {}
    super.dispose();
  }

  Future<void> _loadRooms() async {
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) return;
      final data = await ApiService.getRooms(token);
      if (mounted) setState(() => rooms = data);
    } catch (e) {
      debugPrint('Load rooms error: $e');
    }
  }

  String _formatTime(String? ts) {
    if (ts == null) return '';
    try {
      final dt  = DateTime.parse(ts).toLocal();
      final now = DateTime.now();
      if (dt.day == now.day) {
        return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
      }
      return '${dt.day}/${dt.month}';
    } catch (_) { return ''; }
  }

  Color _avatarColor(String name) {
    final colors = [
      const Color(0xFF7C4DFF), const Color(0xFF448AFF),
      const Color(0xFF00BCD4), const Color(0xFF4CAF50),
      const Color(0xFFFF7043), const Color(0xFFEC407A),
    ];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final me = context.read<AuthProvider>().user;
    if (me == null) return const Scaffold(
        body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 120,
          pinned: true,
          backgroundColor: _purple,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [_purpleDark, _purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight)),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('chatpat',
                              style: TextStyle(color: Colors.white,
                                  fontSize: 28, fontWeight: FontWeight.bold)),
                          Text('Hi, ${me.username} 👋',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 14)),
                        ]),
                      Row(children: [
                        _appBarBtn(Icons.refresh_rounded, _loadRooms),
                        const SizedBox(width: 8),
                        _appBarBtn(Icons.logout_rounded,
                            () => context.read<AuthProvider>().logout()),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Messages',
                    style: TextStyle(fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E))),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: _purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('${rooms.length}',
                      style: const TextStyle(
                          color: _purple, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),

        rooms.isEmpty
            ? SliverFillRemaining(
                child: Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 80, height: 80,
                      decoration: BoxDecoration(
                          color: _purple.withValues(alpha: 0.1),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.chat_bubble_outline_rounded,
                          size: 40, color: _purple)),
                    const SizedBox(height: 16),
                    const Text('No chats yet',
                        style: TextStyle(fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E))),
                    const SizedBox(height: 6),
                    const Text('Tap + to start a conversation',
                        style: TextStyle(color: Colors.grey)),
                  ],
                )),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate((ctx, i) {
                  final room     = rooms[i];
                  final others   = (room['participants'] as List)
                      .where((p) => p['id'] != me.id).toList();
                  final other    = others.isNotEmpty
                      ? others.first : room['participants'].first;
                  final lastMsg  = room['last_message'];
                  final username = other['username']?.toString() ?? 'User';
                  final unread   = room['unread_count'] ?? 0;

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.push(context,
                          FadeSlidePageRoute(page: ChatScreen(
                            roomId:      room['id'],
                            otherUser:   other,
                            callService: _callService,
                          )),
                        ).then((_) => _loadRooms()),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2))],
                          ),
                          child: Row(children: [
                            Stack(children: [
                              CircleAvatar(radius: 26,
                                backgroundColor: _avatarColor(username),
                                child: Text(username[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold))),
                              if (other['is_online'] == true)
                                Positioned(right: 0, bottom: 0,
                                  child: Container(width: 12, height: 12,
                                    decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2)))),
                            ]),
                            const SizedBox(width: 14),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(username,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Color(0xFF1A1A2E))),
                                const SizedBox(height: 4),
                                Text(
                                  lastMsg != null
                                      ? lastMsg['content'] ?? ''
                                      : 'No messages yet',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: unread > 0
                                        ? const Color(0xFF1A1A2E)
                                        : Colors.grey,
                                    fontSize: 13,
                                    fontWeight: unread > 0
                                        ? FontWeight.w600
                                        : FontWeight.normal),
                                ),
                              ],
                            )),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  lastMsg != null
                                      ? _formatTime(lastMsg['timestamp'] ??
                                          lastMsg['created_at'])
                                      : '',
                                  style: TextStyle(fontSize: 11,
                                      color: unread > 0
                                          ? _purple : Colors.grey)),
                                const SizedBox(height: 6),
                                if (unread > 0)
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: const BoxDecoration(
                                        color: _purple,
                                        shape: BoxShape.circle),
                                    child: Text('$unread',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold)))
                                else
                                  const SizedBox(height: 18),
                              ],
                            ),
                          ]),
                        ),
                      ),
                    ),
                  );
                }, childCount: rooms.length),
              ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ]),

      floatingActionButton: FloatingActionButton(
        backgroundColor: _purple,
        elevation: 4,
        child: const Icon(Icons.edit_rounded, color: Colors.white),
        onPressed: () => Navigator.push(context,
          FadeSlidePageRoute(
              page: ContactsScreen(callService: _callService))).
            then((_) => _loadRooms()),
      ),
    );
  }

  Widget _appBarBtn(IconData icon, VoidCallback onTap) => Container(
    decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12)),
    child: IconButton(
        icon: Icon(icon, color: Colors.white), onPressed: onTap),
  );
}