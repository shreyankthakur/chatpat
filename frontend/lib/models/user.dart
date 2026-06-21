class UserModel {
  final int    id;
  final String username, phone, about;
  final bool   isOnline;
  final String? avatar;

  UserModel({required this.id, required this.username,
             required this.phone,  required this.about,
             required this.isOnline, this.avatar});

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: j['id'], username: j['username'], phone: j['phone'],
    about: j['about'] ?? '', isOnline: j['is_online'] ?? false,
    avatar: j['avatar'],
  );
}