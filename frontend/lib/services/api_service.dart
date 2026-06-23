import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';

class ApiService {
  static Map<String, String> _headers({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) headers['Authorization'] = 'Token $token';
    return headers;
  }

  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    try {
      final res = await http
          .post(
            Uri.parse('$BASE_URL/api/auth/login/'),
            headers: _headers(),
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 || res.statusCode == 201) {
        return Map<String, dynamic>.from(jsonDecode(res.body));
      }
      return {'error': 'Server error ${res.statusCode}'};
    } catch (e) {
      debugPrint('Login error: $e');
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> register(
      String username, String phone, String password) async {
    try {
      final res = await http
          .post(
            Uri.parse('$BASE_URL/api/auth/register/'),
            headers: _headers(),
            body: jsonEncode({
              'username': username,
              'phone':    phone,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 || res.statusCode == 201) {
        return Map<String, dynamic>.from(jsonDecode(res.body));
      }
      return {'error': 'Server error ${res.statusCode}'};
    } catch (e) {
      debugPrint('Register error: $e');
      return {'error': e.toString()};
    }
  }

  static Future<List> getUsers(String token) async {
    try {
      final res = await http
          .get(
            Uri.parse('$BASE_URL/api/auth/users/'),
            headers: _headers(token: token),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body) as List;
    } catch (e) {
      debugPrint('Get users error: $e');
      return [];
    }
  }

  static Future<List> getRooms(String token) async {
    try {
      final res = await http
          .get(
            Uri.parse('$BASE_URL/api/chat/rooms/'),
            headers: _headers(token: token),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body) as List;
    } catch (e) {
      debugPrint('Get rooms error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getOrCreateRoom(
      String token, int userId) async {
    try {
      final res = await http
          .post(
            Uri.parse('$BASE_URL/api/chat/rooms/create/'),
            headers: _headers(token: token),
            body: jsonEncode({'user_id': userId}),
          )
          .timeout(const Duration(seconds: 10));
      return Map<String, dynamic>.from(jsonDecode(res.body));
    } catch (e) {
      debugPrint('Get/create room error: $e');
      return {};
    }
  }

  static Future<List> getMessages(String token, int roomId) async {
    try {
      final res = await http
          .get(
            Uri.parse('$BASE_URL/api/chat/rooms/$roomId/messages/'),
            headers: _headers(token: token),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body) as List;
    } catch (e) {
      debugPrint('Get messages error: $e');
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
            body: jsonEncode({'content': content}),
          )
          .timeout(const Duration(seconds: 10));
      return Map<String, dynamic>.from(jsonDecode(res.body));
    } catch (e) {
      debugPrint('Send message error: $e');
      return {};
    }
  }
}