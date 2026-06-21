class RoomModel {
  final int    id;
  final List   participants;
  final Map?   lastMessage;
  final String createdAt;

  RoomModel({required this.id, required this.participants,
             this.lastMessage, required this.createdAt});

  factory RoomModel.fromJson(Map<String, dynamic> j) => RoomModel(
    id:           j['id'],
    participants: j['participants'] ?? [],
    lastMessage:  j['last_message'],
    createdAt:    j['created_at'] ?? '',
  );
}