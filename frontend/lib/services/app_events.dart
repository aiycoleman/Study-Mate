// filepath: frontend/lib/services/app_events.dart
import 'dart:async';

class AppEvents {
  static final AppEvents _instance = AppEvents._internal();
  factory AppEvents() => _instance;
  AppEvents._internal();

  final StreamController<String> _eventController = StreamController<String>.broadcast();

  Stream<String> get events => _eventController.stream;

  void emit(String event) {
    _eventController.add(event);
  }

  void dispose() {
    _eventController.close();
  }
}

// Event types
class AppEventTypes {
  static const String goalAdded = 'goal_added';
  static const String goalDeleted = 'goal_deleted';
  static const String goalUpdated = 'goal_updated';
  static const String quoteAdded = 'quote_added';
  static const String quoteDeleted = 'quote_deleted';
  static const String studySessionAdded = 'study_session_added';
  static const String studySessionDeleted = 'study_session_deleted';
}
