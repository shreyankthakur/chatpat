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

  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    try {
      final res = await http
          .post(Uri.parse('$BASE_URL/api/auth/login/'),
              headers: _headers(),
              body: jsonEncode(
                  {'username': username, 'password': password}))
          .timeout(const Duration(seconds: 15));
      print('Login ${res.statusCode}: ${res.body}');
      if (res.statusCode == 200 || res.statusCode == 201) {
        return Map<String, dynamic>.from(jsonDecode(res.body));
      }
      return {'error': 'Server error ${res.statusCode}'};
    } catch (e) {
      print('Login error: $e');
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
      print('Register ${res.statusCode}: ${res.body}');
      try {
        return Map<String, dynamic>.from(jsonDecode(res.body));
      } catch (_) {
        return {'error': 'Server error ${res.statusCode}'};
      }
    } catch (e) {
      print('Register error: $e');
      return {'error': e.toString()};
    }
  }

  static Future<List> getUsers(String token) async {
    try {
      final res = await http
          .get(Uri.parse('$BASE_URL/api/auth/users/'),
              headers: _headers(token: token))
          .timeout(const Duration(seconds: 15));
      return jsonDecode(res.body);
    } catch (e) {
      print('Get users error: $e');
      return [];
    }
  }

  static Future<List> getRooms(String token) async {
    try {
      final res = await http
          .get(Uri.parse('$BASE_URL/api/chat/rooms/'),
              headers: _headers(token: token))
          .timeout(const Duration(seconds: 15));
      final decoded = jsonDecode(res.body);
      if (decoded is List) return decoded;
      if (decoded is Map && decoded['results'] != null) {
        return decoded['results'];
      }
      return [];
    } catch (e) {
      print('Get rooms error: $e');
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
      return Map<String, dynamic>.from(jsonDecode(res.body));
    } catch (e) {
      print('Get/create room error: $e');
      return {};
    }
  }

  static Future<List> getMessages(String token, int roomId) async {
    try {
      final res = await http
          .get(
              Uri.parse(
                  '$BASE_URL/api/chat/rooms/$roomId/messages/'),
              headers: _headers(token: token))
          .timeout(const Duration(seconds: 15));
      print('getMessages ${res.statusCode}: ${res.body}');
      final decoded = jsonDecode(res.body);
      if (decoded is List) return decoded;
      if (decoded is Map && decoded['results'] != null) {
        return decoded['results'];
      }
      return [];
    } catch (e) {
      print('Get messages error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> sendMessage(
      String token, int roomId, String content) async {
    try {
      final res = await http
          .post(
              Uri.parse(
                  '$BASE_URL/api/chat/rooms/$roomId/messages/send/'),
              headers: _headers(token: token),
              body: jsonEncode({'content': content}))
          .timeout(const Duration(seconds: 15));
      print('Send ${res.statusCode}: ${res.body}');
      if (res.statusCode == 200 || res.statusCode == 201) {
        return Map<String, dynamic>.from(jsonDecode(res.body));
      }
      return {'error': 'Send failed ${res.statusCode}'};
    } catch (e) {
      print('Send error: $e');
      return {'error': e.toString()};
    }
  }
}