import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';

class ApiService {
  static Map<String, String> _headers({String? token}) {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept':       'application/json',
    };
    if (token != null) h['Authorization'] = 'Token $token';
    return h;
  }

  static dynamic _decode(http.Response res) {
    final body = res.body.trim();
    if (body.isEmpty) return null;
    try { return jsonDecode(body); } catch (_) { return null; }
  }

  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    try {
      final res = await http
          .post(Uri.parse('$BASE_URL/api/auth/login/'),
              headers: _headers(),
              body: jsonEncode({'username': username, 'password': password}))
          .timeout(const Duration(seconds: 15));
      final data = _decode(res);
      if (data == null) return {'error': 'Empty response'};
      return Map<String, dynamic>.from(data);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> register(
      String username, String phone, String password) async {
    try {
      final res = await http
          .post(Uri.parse('$BASE_URL/api/auth/register/'),
              headers: _headers(),
              body: jsonEncode({
                'username': username,
                'phone':    phone,
                'password': password,
              }))
          .timeout(const Duration(seconds: 15));
      final data = _decode(res);
      if (data == null) return {'error': 'Empty response'};
      return Map<String, dynamic>.from(data);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<List> getUsers(String token) async {
    try {
      final res = await http
          .get(Uri.parse('$BASE_URL/api/auth/users/'),
              headers: _headers(token: token))
          .timeout(const Duration(seconds: 15));
      final data = _decode(res);
      if (data == null) return [];
      if (data is List) return data;
      if (data is Map && data['results'] != null) return data['results'];
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List> getRooms(String token) async {
    try {
      final res = await http
          .get(Uri.parse('$BASE_URL/api/chat/rooms/'),
              headers: _headers(token: token))
          .timeout(const Duration(seconds: 15));
      final data = _decode(res);
      if (data == null) return [];
      if (data is List) return data;
      if (data is Map && data['results'] != null) return data['results'];
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getOrCreateRoom(
      String token, int userId) async {
    try {
      final res = await http
          .post(Uri.parse('$BASE_URL/api/chat/rooms/create/'),
              headers: _headers(token: token),
              body: jsonEncode({'user_id': userId}))
          .timeout(const Duration(seconds: 15));
      final data = _decode(res);
      if (data == null) return {};
      return Map<String, dynamic>.from(data);
    } catch (e) {
      return {};
    }
  }

  static Future<List> getMessages(String token, int roomId) async {
    try {
      final res = await http
          .get(Uri.parse('$BASE_URL/api/chat/rooms/$roomId/messages/'),
              headers: _headers(token: token))
          .timeout(const Duration(seconds: 15));
      final data = _decode(res);
      if (data == null) return [];
      if (data is List) return data;
      if (data is Map && data['results'] != null) return data['results'];
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> sendMessage(
      String token, int roomId, String content) async {
    try {
      final res = await http
          .post(
              Uri.parse('$BASE_URL/api/chat/rooms/$roomId/messages/send/'),
              headers: _headers(token: token),
              body: jsonEncode({'content': content}))
          .timeout(const Duration(seconds: 15));
      final data = _decode(res);
      if (data == null) return {};
      return Map<String, dynamic>.from(data);
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}