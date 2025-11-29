import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/api_config.dart';

class ApiService {
  final String baseUrl;
  final AuthService auth;

  ApiService({String? baseUrl, AuthService? auth})
      : baseUrl = baseUrl ?? apiBaseUrl,
        auth = auth ?? AuthService();

  /// Helper method to get authorization headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await auth.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Helper to parse error messages from backend responses
  String _parseErrorMessage(int statusCode, String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map && decoded.containsKey('error')) {
        final error = decoded['error'];

        // Check for activation required error
        if (error.toString().toLowerCase().contains('activated') ||
            error.toString().toLowerCase().contains('activation')) {
          return 'Your account is not activated. Please check your email or contact support.';
        }

        // Check for permission errors
        if (error.toString().toLowerCase().contains('permission')) {
          return 'You do not have permission to perform this action.';
        }

        return error.toString();
      }
    } catch (e) {
      // If parsing fails, return generic message
    }

    // Default error messages based on status code
    switch (statusCode) {
      case 401:
        return 'Unauthorized. Please login again.';
      case 403:
        return 'Access forbidden. Your account may not be activated.';
      case 404:
        return 'Resource not found.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return 'Request failed with status $statusCode';
    }
  }

  // ========== HEALTH CHECK ==========
  Future<Map<String, dynamic>> healthCheck() async {
    final uri = Uri.parse('$baseUrl/v1/healthcheck');
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Health check failed: ${res.statusCode}');
  }

  // ========== STUDY SESSIONS ==========
  Future<List<dynamic>> fetchStudySessions() async {
    final uri = Uri.parse('$baseUrl/v1/study-sessions');
    final headers = await _getHeaders();
    final res = await http.get(uri, headers: headers);

    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      if (decoded is Map && decoded.containsKey('study_sessions')) {
        return decoded['study_sessions'] as List<dynamic>;
      } else if (decoded is Map && decoded.containsKey('data')) {
        return decoded['data'] as List<dynamic>;
      } else if (decoded is List) {
        return decoded;
      }
      return [];
    }
    throw Exception(_parseErrorMessage(res.statusCode, res.body));
  }

  Future<Map<String, dynamic>> createStudySession(Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/v1/study-sessions');
    final headers = await _getHeaders();

    print('createStudySession sending data: $data');
    final res = await http.post(uri, headers: headers, body: json.encode(data));

    print('createStudySession response status: ${res.statusCode}');
    print('createStudySession response body: ${res.body}');

    if (res.statusCode == 201 || res.statusCode == 200) {
      final result = json.decode(res.body) as Map<String, dynamic>;
      print('createStudySession result: $result');
      return result;
    }
    throw Exception(_parseErrorMessage(res.statusCode, res.body));
  }

  Future<Map<String, dynamic>> getStudySession(String id) async {
    final uri = Uri.parse('$baseUrl/v1/study-sessions/$id');
    final headers = await _getHeaders();
    final res = await http.get(uri, headers: headers);

    if (res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    }
    throw Exception(_parseErrorMessage(res.statusCode, res.body));
  }

  Future<Map<String, dynamic>> updateStudySession(String id, Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/v1/study-sessions/$id');
    final headers = await _getHeaders();
    final res = await http.patch(uri, headers: headers, body: json.encode(data));

    if (res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    }
    throw Exception(_parseErrorMessage(res.statusCode, res.body));
  }

  Future<void> deleteStudySession(String id) async {
    final uri = Uri.parse('$baseUrl/v1/study-sessions/$id');
    final headers = await _getHeaders();
    final res = await http.delete(uri, headers: headers);

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(_parseErrorMessage(res.statusCode, res.body));
    }
  }

  // ========== GOALS ==========
  Future<List<dynamic>> fetchGoals() async {
    final uri = Uri.parse('$baseUrl/v1/goals');
    final headers = await _getHeaders();

    print('fetchGoals making request to: $uri');
    print('fetchGoals headers: $headers');
    final res = await http.get(uri, headers: headers);

    print('fetchGoals response status: ${res.statusCode}');
    print('fetchGoals response body: ${res.body}');

    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      if (decoded is Map && decoded.containsKey('goals')) {
        print('fetchGoals returning ${(decoded['goals'] as List).length} goals');
        return decoded['goals'] as List<dynamic>;
      } else if (decoded is Map && decoded.containsKey('data')) {
        print('fetchGoals returning ${(decoded['data'] as List).length} goals from data field');
        return decoded['data'] as List<dynamic>;
      } else if (decoded is List) {
        print('fetchGoals returning ${decoded.length} goals as direct list');
        return decoded;
      }
      print('fetchGoals returning empty list - unexpected format');
      return [];
    }
    throw Exception(_parseErrorMessage(res.statusCode, res.body));
  }

  Future<Map<String, dynamic>> createGoal(Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/v1/goals');
    final headers = await _getHeaders();

    print('createGoal sending data: $data');
    final res = await http.post(uri, headers: headers, body: json.encode(data));

    print('createGoal response status: ${res.statusCode}');
    print('createGoal response body: ${res.body}');

    if (res.statusCode == 201 || res.statusCode == 200) {
      final result = json.decode(res.body) as Map<String, dynamic>;
      print('createGoal result: $result');
      return result;
    }
    throw Exception(_parseErrorMessage(res.statusCode, res.body));
  }

  Future<Map<String, dynamic>> getGoal(String id) async {
    final uri = Uri.parse('$baseUrl/v1/goals/$id');
    final headers = await _getHeaders();
    final res = await http.get(uri, headers: headers);

    if (res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    }
    throw Exception(_parseErrorMessage(res.statusCode, res.body));
  }

  Future<Map<String, dynamic>> updateGoal(String id, Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/v1/goals/$id');
    final headers = await _getHeaders();
    final res = await http.patch(uri, headers: headers, body: json.encode(data));

    if (res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    }
    throw Exception(_parseErrorMessage(res.statusCode, res.body));
  }

  Future<void> deleteGoal(String id) async {
    final uri = Uri.parse('$baseUrl/v1/goals/$id');
    final headers = await _getHeaders();
    final res = await http.delete(uri, headers: headers);

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(_parseErrorMessage(res.statusCode, res.body));
    }
  }

  // ========== QUOTES ==========
  Future<List<dynamic>> fetchQuotes() async {
    final uri = Uri.parse('$baseUrl/v1/quotes');
    final headers = await _getHeaders();
    final res = await http.get(uri, headers: headers);

    print('fetchQuotes response status: ${res.statusCode}');
    print('fetchQuotes response body: ${res.body}');

    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      if (decoded is Map && decoded.containsKey('quotes')) {
        print('fetchQuotes returning ${(decoded['quotes'] as List).length} quotes');
        return decoded['quotes'] as List<dynamic>;
      } else if (decoded is Map && decoded.containsKey('data')) {
        print('fetchQuotes returning ${(decoded['data'] as List).length} quotes from data field');
        return decoded['data'] as List<dynamic>;
      } else if (decoded is List) {
        print('fetchQuotes returning ${decoded.length} quotes as direct list');
        return decoded;
      }
      print('fetchQuotes returning empty list - unexpected format');
      return [];
    }
    throw Exception(_parseErrorMessage(res.statusCode, res.body));
  }

  Future<Map<String, dynamic>> createQuote(Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/v1/quotes');
    final headers = await _getHeaders();

    print('createQuote sending data: $data');
    final res = await http.post(uri, headers: headers, body: json.encode(data));

    print('createQuote response status: ${res.statusCode}');
    print('createQuote response body: ${res.body}');

    if (res.statusCode == 201 || res.statusCode == 200) {
      final result = json.decode(res.body) as Map<String, dynamic>;
      print('createQuote result: $result');
      return result;
    }
    throw Exception(_parseErrorMessage(res.statusCode, res.body));
  }

  Future<Map<String, dynamic>> getQuote(String id) async {
    final uri = Uri.parse('$baseUrl/v1/quotes/$id');
    final headers = await _getHeaders();
    final res = await http.get(uri, headers: headers);

    if (res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    }
    throw Exception(_parseErrorMessage(res.statusCode, res.body));
  }

  Future<Map<String, dynamic>> updateQuote(String id, Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/v1/quotes/$id');
    final headers = await _getHeaders();
    final res = await http.patch(uri, headers: headers, body: json.encode(data));

    if (res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    }
    throw Exception(_parseErrorMessage(res.statusCode, res.body));
  }

  Future<void> deleteQuote(String id) async {
    final uri = Uri.parse('$baseUrl/v1/quotes/$id');
    final headers = await _getHeaders();
    final res = await http.delete(uri, headers: headers);

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(_parseErrorMessage(res.statusCode, res.body));
    }
  }

  // ========== USERS ==========
  Future<List<dynamic>> fetchUsers() async {
    final uri = Uri.parse('$baseUrl/v1/users/accounts');
    final headers = await _getHeaders();
    final res = await http.get(uri, headers: headers);

    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      if (decoded is Map && decoded.containsKey('users')) {
        return decoded['users'] as List<dynamic>;
      } else if (decoded is List) {
        return decoded;
      }
      return [];
    }
    throw Exception(_parseErrorMessage(res.statusCode, res.body));
  }

  Future<Map<String, dynamic>> updateUser(String id, Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/v1/users/update/$id');
    final headers = await _getHeaders();
    final res = await http.patch(uri, headers: headers, body: json.encode(data));

    if (res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    }
    throw Exception(_parseErrorMessage(res.statusCode, res.body));
  }

  Future<Map<String, dynamic>> updateUserPassword(String id, Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/v1/users/update-password/$id');
    final headers = await _getHeaders();
    final res = await http.patch(uri, headers: headers, body: json.encode(data));

    if (res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    }
    throw Exception(_parseErrorMessage(res.statusCode, res.body));
  }

  Future<void> deleteUser(String id) async {
    final uri = Uri.parse('$baseUrl/v1/users/delete/$id');
    final headers = await _getHeaders();
    final res = await http.delete(uri, headers: headers);

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(_parseErrorMessage(res.statusCode, res.body));
    }
  }

  Future<void> activateUser(Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/v1/users/activated');
    final headers = await _getHeaders();
    final res = await http.put(uri, headers: headers, body: json.encode(data));

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(_parseErrorMessage(res.statusCode, res.body));
    }
  }

  // ========== STATISTICS ==========
  /// Helper method to calculate total study hours from sessions
  Future<double> getTotalStudyHours() async {
    try {
      final sessions = await fetchStudySessions();
      double totalHours = 0.0;

      for (final session in sessions) {
        if (session is Map<String, dynamic>) {
          final duration = session['duration'] ?? session['duration_minutes'] ?? session['length'] ?? 0;
          if (duration is int) {
            totalHours += duration / 60.0;
          } else if (duration is double) {
            totalHours += duration;
          }
        }
      }

      return totalHours;
    } catch (e) {
      print('Error calculating study hours: $e');
      return 0.0;
    }
  }
}
