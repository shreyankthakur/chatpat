import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  String?    token;
  UserModel? user;
  bool       isLoading  = false;
  String?    errorMessage;

  Future<bool> login(String username, String password) async {
    isLoading    = true;
    errorMessage = null;
    notifyListeners();
    try {
      final data = await ApiService.login(username, password);
      if (data['error'] != null) {
        errorMessage = data['error'].toString();
        isLoading = false;
        notifyListeners();
        return false;
      }
      if (data['token'] != null && data['user'] != null) {
        token = data['token'].toString();
        user  = UserModel.fromJson(Map<String, dynamic>.from(data['user']));
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token',    token!);
        await prefs.setInt('user_id',     user!.id);
        await prefs.setString('username', user!.username);
        await prefs.setString('about',    user!.about);
        isLoading = false;
        notifyListeners();
        return true;
      }
      errorMessage = 'Invalid credentials';
      isLoading    = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      errorMessage = e.toString();
      isLoading    = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String username, String phone, String password) async {
    isLoading    = true;
    errorMessage = null;
    notifyListeners();
    try {
      final data = await ApiService.register(username, phone, password);
      if (data['error'] != null) {
        errorMessage = data['error'].toString();
        isLoading    = false;
        notifyListeners();
        return false;
      }
      if (data['token'] != null && data['user'] != null) {
        token = data['token'].toString();
        user  = UserModel.fromJson(Map<String, dynamic>.from(data['user']));
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token',    token!);
        await prefs.setInt('user_id',     user!.id);
        await prefs.setString('username', user!.username);
        await prefs.setString('about',    user!.about);
        isLoading = false;
        notifyListeners();
        return true;
      }
      if (data['username'] != null) {
        errorMessage = data['username'] is List
            ? data['username'][0]
            : data['username'].toString();
      } else if (data['phone'] != null) {
        errorMessage = data['phone'] is List
            ? data['phone'][0]
            : data['phone'].toString();
      } else {
        errorMessage = 'Registration failed.';
      }
      isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Register error: $e');
      errorMessage = e.toString();
      isLoading    = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    token        = null;
    user         = null;
    errorMessage = null;
    final prefs  = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    if (token != null) {
      final id       = prefs.getInt('user_id');
      final username = prefs.getString('username');
      final about    = prefs.getString('about') ?? 'Hey there!';
      if (id != null && username != null) {
        user = UserModel(
          id:       id,
          username: username,
          phone:    '',
          about:    about,
          isOnline: false,
        );
      }
    }
    notifyListeners();
  }
}