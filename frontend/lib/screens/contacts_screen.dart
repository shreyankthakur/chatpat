import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/call_service.dart';
import 'chat_screen.dart';

class ContactsScreen extends StatefulWidget {
  final CallService callService;
  const ContactsScreen({super.key, required this.callService});
  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List   users   = [];
  bool   loading = true;
  String search  = '';

  static const _purple     = Color(0xFF7C4DFF);
  static const _purpleDark = Color(0xFF512DA8);
  static const _bg         = Color(0xFFF5F3FF);

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) return;
      final data = await ApiService.getUsers(token);
      if (mounted) setState(() { users = data; loading = false; });
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _openChat(Map other) async {
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) return;
      final room = await ApiService.getOrCreateRoom(token, other['id']);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => ChatScreen(
          roomId:      room['id'],
          otherUser:   Map<String, dynamic>.from(other),
          callService: widget.callService,
        ),
      ));
    } catch (e) {
      debugPrint('Open chat error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         const Text('Could not open chat. Try again.'),
          backgroundColor: _purpleDark,
          behavior:        SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  List get _filtered => search.isEmpty
      ? users
      : users.where((u) => u['username']
          .toString().toLowerCase()
          .contains(search.toLowerCase())).toList();

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
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: _purple,
          iconTheme: const IconThemeData(color: Colors.white),
          expandedHeight: 140,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [_purpleDark, _purple],
                    begin: Alignment.topLeft,
                    end:   Alignment.bottomRight)),
              child: SafeArea(child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text('New Chat',
                        style: TextStyle(color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${users.length} contacts',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  ],
                ),
              )),
            ),
          ),
        ),

        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8)],
            ),
            child: TextField(
              onChanged: (v) => setState(() => search = v),
              decoration: const InputDecoration(
                hintText:     'Search contacts...',
                hintStyle:    TextStyle(color: Colors.grey),
                prefixIcon:   Icon(Icons.search_rounded, color: _purple),
                border:       InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
          ),
        )),

        loading
            ? const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(
                    color: _purple)))
            : _filtered.isEmpty
                ? SliverFillRemaining(child: Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 72, height: 72,
                        decoration: BoxDecoration(
                            color: _purple.withValues(alpha: 0.1),
                            shape: BoxShape.circle),
                        child: const Icon(
                            Icons.people_outline_rounded,
                            size: 36, color: _purple)),
                      const SizedBox(height: 16),
                      const Text('No contacts found',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 15)),
                    ],
                  )))
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final u        = _filtered[i];
                          final username =
                              u['username']?.toString() ?? 'Unknown';
                          final about =
                              u['about']?.toString() ?? 'Hey there!';
                          final isOnline = u['is_online'] == true;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _openChat(u),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(16),
                                    boxShadow: [BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2))],
                                  ),
                                  child: Row(children: [
                                    Stack(children: [
                                      CircleAvatar(radius: 26,
                                        backgroundColor:
                                            _avatarColor(username),
                                        child: Text(
                                          username.isNotEmpty
                                              ? username[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight:
                                                  FontWeight.bold))),
                                      if (isOnline)
                                        Positioned(right: 0, bottom: 0,
                                          child: Container(
                                              width: 12, height: 12,
                                              decoration: BoxDecoration(
                                                  color: Colors.green,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                      color: Colors.white,
                                                      width: 2)))),
                                    ]),
                                    const SizedBox(width: 14),
                                    Expanded(child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(username,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: Color(0xFF1A1A2E))),
                                        const SizedBox(height: 3),
                                        Text(about,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 13)),
                                      ],
                                    )),
                                    Container(
                                      width: 36, height: 36,
                                      decoration: BoxDecoration(
                                          color: _purple
                                              .withValues(alpha: 0.1),
                                          shape: BoxShape.circle),
                                      child: const Icon(
                                          Icons.chat_bubble_outline_rounded,
                                          color: _purple, size: 18)),
                                  ]),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: _filtered.length,
                      ),
                    ),
                  ),
      ]),
    );
  }
}