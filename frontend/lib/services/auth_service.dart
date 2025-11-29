import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AuthService {
  final String baseUrl;
  AuthService({String? baseUrl}) : baseUrl = baseUrl ?? apiBaseUrl;

  /// Login: calls backend POST /v1/tokens/authentication and stores token if returned.
  /// Tries both username and email approaches based on input.
  Future<bool> login(String usernameOrEmail, String password) async {
    final uri = Uri.parse('$baseUrl/v1/tokens/authentication');

    // Try multiple approaches - backend might expect different field names
    List<Map<String, dynamic>> payloads = [];

    // Check if input looks like email or username
    if (usernameOrEmail.contains('@')) {
      // Looks like email - try email field first, then username field
      payloads.add({'email': usernameOrEmail, 'password': password});
      payloads.add({'username': usernameOrEmail, 'password': password});
    } else {
      // Looks like username - try username field first, then email field
      payloads.add({'username': usernameOrEmail, 'password': password});
      payloads.add({'email': usernameOrEmail, 'password': password});
    }

    // Try each payload
    String lastError = '';
    for (final payload in payloads) {
      try {
        print('🔐 AuthService.login: Attempting login');
        print('📤 URL: $uri');
        print('📦 Payload: ${json.encode(payload)}');

        final res = await http.post(uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(payload)).timeout(const Duration(seconds: 10));

        print('📥 Response Status: ${res.statusCode}');
        print('📥 Response Body: ${res.body}');
        print('📥 Response Headers: ${res.headers}');

        if (res.statusCode == 200 || res.statusCode == 201) {
          final dynamic decoded = json.decode(res.body);

          if (decoded is Map<String, dynamic>) {
            final token = _extractTokenFromMap(decoded);
            if (token != null && token.isNotEmpty) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('auth_token', token);
              if (decoded.containsKey('user')) {
                await prefs.setString('user_json', json.encode(decoded['user']));
              } else {
                await prefs.setString('user_json', json.encode({'username': usernameOrEmail}));
              }
              return true;
            } else {
              lastError = 'Login succeeded but no token found in response: ${res.body}';
              print(lastError);
            }
          } else if (decoded is String) {
            // Sometimes APIs return the token as a bare string
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('auth_token', decoded);
            await prefs.setString('user_json', json.encode({'username': usernameOrEmail}));
            return true;
          } else {
            lastError = 'Unexpected response format: ${res.body}';
            print(lastError);
          }
        } else if (res.statusCode == 401) {
          lastError = 'Invalid credentials';
          print('AuthService.login: Invalid credentials for ${json.encode(payload)}');
          // Continue to try next payload instead of breaking
        } else {
          lastError = 'HTTP ${res.statusCode}: ${res.body}';
          print(lastError);
        }
      } catch (e) {
        lastError = 'Network error: $e';
        print('AuthService.login: error $e');
      }
    }

    // All payloads failed
    print('AuthService.login: all login attempts failed. Last error: $lastError');
    return false;
  }

  /// Register a new user
  Future<bool> register(String name, String email, String password) async {
    final uri = Uri.parse('$baseUrl/v1/users');

    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': name,  // Changed from 'name' to 'username'
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      print('AuthService.register: response ${res.statusCode}: ${res.body}');

      if (res.statusCode == 201 || res.statusCode == 200) {
        // Registration successful - DO NOT auto-login, user needs to activate first
        return true;
      } else {
        print('AuthService.register: registration failed ${res.statusCode}');
        throw Exception('Registration failed: ${res.body}');
      }
    } catch (e) {
      print('AuthService.register: error $e');
      throw Exception('Registration failed: $e');
    }
  }

  /// Get stored authentication token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    print('AuthService.getToken: retrieved token: ${token?.substring(0, 10)}...');
    return token;
  }

  /// Clear stored authentication data
  Future<void> logout() async {
    print('AuthService.logout: clearing stored data');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_json');
  }

  /// Helper method to extract token from various response formats
  String? _extractTokenFromMap(Map<String, dynamic> map) {
    // Try different possible token field names
    for (final key in ['authentication_token', 'token', 'auth_token', 'access_token']) {
      if (map.containsKey(key)) {
        final value = map[key];
        if (value is String && value.isNotEmpty) {
          return value;
        } else if (value is Map<String, dynamic> && value.containsKey('token')) {
          return value['token'] as String?;
        }
      }
    }

    // Check nested structures
    if (map.containsKey('data') && map['data'] is Map<String, dynamic>) {
      return _extractTokenFromMap(map['data'] as Map<String, dynamic>);
    }

    return null;
  }

  /// Test connection to backend
  Future<bool> testConnection() async {
    try {
      final uri = Uri.parse('$baseUrl/v1/healthcheck');
      print('AuthService.testConnection: testing $uri');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      print('AuthService.testConnection: response ${res.statusCode}: ${res.body}');
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      print('AuthService.testConnection: error $e');
      return false;
    }
  }

  /// Activate user account with token
  Future<bool> activateUser(String token) async {
    final uri = Uri.parse('$baseUrl/v1/users/activated');

    try {
      final res = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': token}),
      ).timeout(const Duration(seconds: 10));

      print('AuthService.activateUser: response ${res.statusCode}: ${res.body}');

      if (res.statusCode == 200) {
        return true;
      } else {
        throw Exception('Activation failed: ${res.body}');
      }
    } catch (e) {
      print('AuthService.activateUser: error $e');
      throw Exception('Failed to activate account: $e');
    }
  }
}
