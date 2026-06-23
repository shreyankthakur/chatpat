import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/call_service.dart';
import 'chat_screen.dart';

class ContactsScreen extends StatefulWidget {
  final CallService callService;

  const ContactsScreen({super.key, required this.callService});
  @override State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List   users   = [];
  bool   loading = true;
  String search  = '';

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
      debugPrint('Load users error: $e');
    }
  }

  Future<void> _openChat(Map other) async {
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) return;
      final room = await ApiService.getOrCreateRoom(token, other['id']);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              roomId:      room['id'],
              otherUser:   Map<String, dynamic>.from(other),
              callService: widget.callService,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Open chat error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open chat. Try again.')));
      }
    }
  }

  List get _filtered => search.isEmpty
      ? users
      : users.where((u) =>
          u['username'].toString().toLowerCase()
            .contains(search.toLowerCase())).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFFB71C1C),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'New Chat',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFFB71C1C),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() => search = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText:      'Search users...',
                hintStyle:     const TextStyle(color: Colors.white60),
                prefixIcon:    const Icon(Icons.search, color: Colors.white60),
                filled:        true,
                fillColor:     Colors.white12,
                border:        OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFB71C1C)))
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 70, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              search.isEmpty
                                  ? 'No users found'
                                  : 'No results for "$search"',
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 72),
                        itemBuilder: (ctx, i) {
                          final u        = _filtered[i];
                          final username = u['username']?.toString() ?? 'Unknown';
                          final about    = u['about']?.toString() ?? 'Hey there!';
                          final isOnline = u['is_online'] == true;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: const Color(0xFFE53935),
                                  child: Text(
                                    username.isNotEmpty
                                        ? username[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                if (isOnline)
                                  Positioned(
                                    right: 0, bottom: 0,
                                    child: Container(
                                      width: 12, height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(
                              username,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                            subtitle: Text(
                              about,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13),
                            ),
                            trailing: const Icon(
                                Icons.chat_bubble_outline,
                                color: Color(0xFFB71C1C)),
                            onTap: () => _openChat(u),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}