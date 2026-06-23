import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/background_service.dart';

class AuthProvider extends ChangeNotifier {
  String? token;
  UserModel? user;
  bool isLoading = false;
  String? errorMessage;

  Future<bool> login(String username, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = await ApiService.login(username, password);

      if (data['error'] != null) {
        errorMessage = data['error'].toString();
        return false;
      }

      if (data['token'] != null && data['user'] != null) {
        token = data['token'].toString();
        user = UserModel.fromJson(Map<String, dynamic>.from(data['user']));

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token!);
        await prefs.setInt('user_id', user!.id);
        await prefs.setString('username', user!.username);
        await prefs.setString('about', user!.about);

        // FIX: wrapped in try/catch so a BackgroundService failure
        // doesn't prevent login from succeeding
        try {
          await BackgroundService.updateCredentials(
            userId: user!.id,
            token: token!,
          );
        } catch (e) {
          debugPrint('BackgroundService credentials error (login): $e');
        }

        return true;
      } else {
        errorMessage = 'Invalid credentials';
        return false;
      }
    } catch (e) {
      debugPrint('Login error: $e');
      errorMessage = e.toString();
      return false;
    } finally {
      // FIX: always runs, so isLoading is never stuck as true
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String username, String phone, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = await ApiService.register(username, phone, password);

      if (data['error'] != null) {
        errorMessage = data['error'].toString();
        return false;
      }

      if (data['token'] != null && data['user'] != null) {
        token = data['token'].toString();
        user = UserModel.fromJson(Map<String, dynamic>.from(data['user']));

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token!);
        await prefs.setInt('user_id', user!.id);
        await prefs.setString('username', user!.username);
        await prefs.setString('about', user!.about);

        try {
          await BackgroundService.updateCredentials(
            userId: user!.id,
            token: token!,
          );
        } catch (e) {
          debugPrint('BackgroundService credentials error (register): $e');
        }

        return true;
      } else {
        errorMessage = 'Registration failed. Check your details.';
        return false;
      }
    } catch (e) {
      debugPrint('Register error: $e');
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      BackgroundService.stop();
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      token = null;
      user = null;
      errorMessage = null;
      notifyListeners();
    }
  }

  Future<void> tryAutoLogin() async {
    isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('token');

      if (savedToken == null) return; // no saved session

      final id       = prefs.getInt('user_id');
      final username = prefs.getString('username');
      final about    = prefs.getString('about') ?? 'Hey there!';

      if (id == null || username == null) {
        // Partial/corrupt prefs — clear and treat as logged out
        await prefs.clear();
        return;
      }

      token = savedToken;
      user = UserModel(
        id:       id,
        username: username,
        phone:    '',
        about:    about,
        isOnline: false,
      );

      // FIX: wrapped so a BackgroundService failure doesn't
      // prevent the user from being restored as logged in
      try {
        await BackgroundService.updateCredentials(
          userId: user!.id,
          token:  token!,
        );
      } catch (e) {
        debugPrint('BackgroundService credentials error (autoLogin): $e');
      }
    } catch (e) {
      debugPrint('tryAutoLogin error: $e');
      token = null;
      user  = null;
    } finally {
      // FIX: always runs — app never stuck on loading screen
      isLoading = false;
      notifyListeners();
    }
  }
}