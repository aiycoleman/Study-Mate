// filepath: frontend/lib/services/api_service_MOCK.dart
// TEMPORARY MOCK VERSION - Use this while backend is down

import 'dart:convert';
import 'dart:math';

class ApiService {
  final String baseUrl = 'http://mock-backend';

  // Mock data storage
  static List<Map<String, dynamic>> _mockGoals = [];
  static List<Map<String, dynamic>> _mockQuotes = [];
  static List<Map<String, dynamic>> _mockStudySessions = [];
  static int _nextId = 1;

  /// Helper method to get authorization headers (mock)
  Future<Map<String, String>> _getHeaders() async {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer mock-token-123',
    };
  }

  // ========== HEALTH CHECK ==========
  Future<Map<String, dynamic>> healthCheck() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {'status': 'ok', 'message': 'Mock backend is healthy'};
  }

  // ========== STUDY SESSIONS ==========
  Future<List<dynamic>> fetchStudySessions() async {
    await Future.delayed(const Duration(milliseconds: 300));
    print('MOCK: Fetching ${_mockStudySessions.length} study sessions');
    return _mockStudySessions;
  }

  Future<Map<String, dynamic>> createStudySession(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final session = {
      'id': _nextId++,
      'session_id': _nextId - 1,
      'title': data['title'] ?? 'Study Session',
      'subject': data['subject'] ?? data['title'] ?? 'General',
      'description': data['description'] ?? '',
      'start_time': data['start_time'] ?? DateTime.now().toIso8601String(),
      'end_time': data['end_time'] ?? DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
      'duration': data['duration'] ?? 60,
      'is_completed': data['is_completed'] ?? false,
      'created_at': DateTime.now().toIso8601String(),
    };

    _mockStudySessions.insert(0, session);
    print('MOCK: Created study session - ${session['title']}');

    return {'study_session': session};
  }

  Future<Map<String, dynamic>> updateStudySession(String id, Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _mockStudySessions.indexWhere((s) => s['id'].toString() == id || s['session_id'].toString() == id);
    if (index != -1) {
      _mockStudySessions[index] = {..._mockStudySessions[index], ...data};
      print('MOCK: Updated study session $id');
      return {'study_session': _mockStudySessions[index]};
    }

    throw Exception('Study session not found');
  }

  Future<void> deleteStudySession(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));

    _mockStudySessions.removeWhere((s) => s['id'].toString() == id || s['session_id'].toString() == id);
    print('MOCK: Deleted study session $id');
  }

  // ========== GOALS ==========
  Future<List<dynamic>> fetchGoals() async {
    await Future.delayed(const Duration(milliseconds: 300));
    print('MOCK: Fetching ${_mockGoals.length} goals');
    return _mockGoals;
  }

  Future<Map<String, dynamic>> createGoal(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final goal = {
      'id': _nextId++,
      'goal_id': _nextId - 1,
      'goal_text': data['goal_text'] ?? data['title'] ?? 'New Goal',
      'target_date': data['target_date'] ?? DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      'is_completed': data['is_completed'] ?? false,
      'created_at': DateTime.now().toIso8601String(),
    };

    _mockGoals.insert(0, goal);
    print('MOCK: Created goal - ${goal['goal_text']}');

    return {'goal': goal};
  }

  Future<Map<String, dynamic>> updateGoal(String id, Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _mockGoals.indexWhere((g) => g['id'].toString() == id || g['goal_id'].toString() == id);
    if (index != -1) {
      _mockGoals[index] = {..._mockGoals[index], ...data};
      print('MOCK: Updated goal $id');
      return {'goal': _mockGoals[index]};
    }

    throw Exception('Goal not found');
  }

  Future<void> deleteGoal(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));

    _mockGoals.removeWhere((g) => g['id'].toString() == id || g['goal_id'].toString() == id);
    print('MOCK: Deleted goal $id');
  }

  // ========== QUOTES ==========
  Future<List<dynamic>> fetchQuotes() async {
    await Future.delayed(const Duration(milliseconds: 300));
    print('MOCK: Fetching ${_mockQuotes.length} quotes');
    return _mockQuotes;
  }

  Future<Map<String, dynamic>> createQuote(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final quote = {
      'id': _nextId++,
      'quote_id': _nextId - 1,
      'content': data['content'] ?? data['text'] ?? 'Inspirational quote',
      'username': data['username'] ?? data['author'] ?? 'Anonymous',
      'created_at': DateTime.now().toIso8601String(),
    };

    _mockQuotes.insert(0, quote);
    print('MOCK: Created quote - ${quote['content'].substring(0, 30)}...');

    return {'quote': quote};
  }

  Future<void> deleteQuote(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));

    _mockQuotes.removeWhere((q) => q['id'].toString() == id || q['quote_id'].toString() == id);
    print('MOCK: Deleted quote $id');
  }

  // ========== STATISTICS ==========
  Future<double> getTotalStudyHours() async {
    await Future.delayed(const Duration(milliseconds: 200));

    double total = 0.0;
    for (final session in _mockStudySessions) {
      final duration = session['duration'] ?? 60;
      total += duration / 60.0;
    }

    print('MOCK: Total study hours calculated: ${total.toStringAsFixed(1)}');
    return total;
  }

  // ========== GOOGLE CALENDAR INTEGRATION ==========
  Future<bool> syncStudySessionToCalendar(String sessionId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    print('MOCK: Calendar sync for session $sessionId (mock success)');
    return true;
  }

  Future<Map<String, dynamic>> getCalendarStatus() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {'connected': false, 'email': null};
  }

  Future<bool> saveCalendarCredentials(Map<String, dynamic> credentials) async {
    await Future.delayed(const Duration(milliseconds: 300));
    print('MOCK: Saved calendar credentials');
    return true;
  }

  // ========== USERS ==========
  Future<void> activateUser(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 400));
    print('MOCK: User activation successful');
  }
}
