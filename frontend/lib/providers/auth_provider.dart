// filepath: frontend/lib/providers/auth_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();

  bool initialized = false;
  bool isAuthenticated = false;
  Map<String, dynamic>? user;
  String? lastError;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      final token = await _auth.getToken();
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_json');
      if (userJson != null) {
        try {
          user = json.decode(userJson) as Map<String, dynamic>;
        } catch (_) {
          user = {'username': userJson};
        }
      }
      isAuthenticated = token != null && token.isNotEmpty;
    } catch (e) {
      // keep defaults
    } finally {
      initialized = true;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    lastError = null;
    try {
      print('AuthProvider.login: Attempting login for $username');

      final ok = await _auth.login(username, password);
      if (ok) {
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString('user_json');
        if (userJson != null) {
          user = json.decode(userJson) as Map<String, dynamic>;
        }
        isAuthenticated = true;
        notifyListeners();
        print('AuthProvider.login: Login successful');
        return true;
      }

      lastError = 'Invalid credentials. Please check your email/username and password.';
      print('AuthProvider.login: Login failed - invalid credentials');
      notifyListeners();
      return false;
    } catch (e) {
      final errorMessage = e.toString();
      print('AuthProvider.login: Login exception: $errorMessage');

      // Provide more specific error messages
      if (errorMessage.contains('Invalid credentials')) {
        lastError = 'Invalid credentials. Please check your email/username and password.';
      } else if (errorMessage.contains('not activated') || errorMessage.contains('activation')) {
        lastError = 'Account not activated. Please check your email for activation instructions.';
      } else if (errorMessage.contains('Network')) {
        lastError = 'Network error. Please check your connection.';
      } else {
        lastError = errorMessage.replaceFirst('Exception: ', '');
      }

      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    lastError = null;
    try {
      final ok = await _auth.register(name, email, password);
      if (ok) {
        // AuthService.register tries to login; re-load stored user/token
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString('user_json');
        if (userJson != null) {
          try {
            user = json.decode(userJson) as Map<String, dynamic>;
          } catch (_) {
            user = {'username': userJson};
          }
        }
        isAuthenticated = true;
        notifyListeners();
        return true;
      } else {
        lastError = 'Registration failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.logout();
    isAuthenticated = false;
    user = null;
    notifyListeners();
  }
}

