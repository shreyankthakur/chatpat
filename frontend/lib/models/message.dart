class MessageModel {
  final int    id, senderId;
  final String content, timestamp;
  bool         isRead;

  MessageModel({required this.id, required this.senderId,
                required this.content, required this.timestamp,
                required this.isRead});

  factory MessageModel.fromJson(Map<String, dynamic> j) => MessageModel(
    id: j['id'],
    senderId: j['sender'] is Map ? j['sender']['id'] : j['sender_id'],
    content: j['content'],
    timestamp: j['timestamp'],
    isRead: j['is_read'] ?? false,
  );
}