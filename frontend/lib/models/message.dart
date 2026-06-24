class MessageModel {
  final int    id, senderId;
  final String content, timestamp;
  bool         isRead;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.isRead,
  });

  factory MessageModel.fromJson(Map<String, dynamic> j) => MessageModel(
        id:        j['id'] ?? 0,
        senderId:  j['sender'] is Map ? j['sender']['id'] : (j['sender_id'] ?? 0),
        content:   j['content'] ?? '',
        timestamp: j['timestamp'] ?? DateTime.now().toIso8601String(),
        isRead:    j['is_read'] ?? false,
      );
}