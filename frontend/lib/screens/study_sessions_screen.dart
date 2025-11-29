import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/app_events.dart';
import 'add_study_session_screen.dart';
import 'edit_study_session_screen.dart'; // Edit functionality
import 'study_timer_screen.dart'; // Timer functionality
import 'dart:async';

class StudySessionsScreen extends StatefulWidget {
  const StudySessionsScreen({Key? key}) : super(key: key);

  @override
  State<StudySessionsScreen> createState() => _StudySessionsScreenState();
}

class _StudySessionsScreenState extends State<StudySessionsScreen> {
  final ApiService _api = ApiService();
  final AppEvents _events = AppEvents();
  List<dynamic> _sessions = [];
  bool _isLoading = true;
  String? _error;
  late StreamSubscription<String> _eventSubscription;

  @override
  void initState() {
    super.initState();
    _loadSessions();

    // Listen for app events
    _eventSubscription = _events.events.listen((event) {
      if (event == AppEventTypes.studySessionAdded ||
          event == AppEventTypes.studySessionDeleted) {
        print('Study sessions screen received event: $event, reloading...');
        _loadSessions();
      }
    });
  }


  @override
  void dispose() {
    _eventSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _api.fetchStudySessions();
      if (mounted) {
        setState(() {
          _sessions = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addSession() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const AddStudySessionScreen()),
    );

    if (result != null) {
      try {
        print('Creating study session with data: $result');
        final response = await _api.createStudySession(result);
        print('API response for createStudySession: $response');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Study session added successfully')),
          );

          // Always reload sessions from server to ensure consistency
          print('Reloading study sessions from server...');
          await _loadSessions();

          // Also emit event to notify other screens
          _events.emit(AppEventTypes.studySessionAdded);

          // Session created successfully - reload the list
          await _loadSessions();
        }
      } catch (e) {
        print('Error creating study session: $e');
        if (mounted) {
          // Check if it's a parsing error but the session was actually created
          if (e.toString().contains('unknown field') || e.toString().contains('study_session')) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Study session created successfully (reloading...)'),
                backgroundColor: Colors.orange,
              ),
            );
            // Reload to get the actual created session
            await _loadSessions();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to add study session: $e')),
            );
          }
        }
      }
    }
  }

  Future<void> _editSession(dynamic session) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => EditStudySessionScreen(session: session)),
    );

    if (result != null) {
      final sessionId = session['id']?.toString() ?? session['session_id']?.toString();
      if (sessionId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot edit session: missing ID')),
        );
        return;
      }

      try {
        print('Updating session $sessionId with data: $result');
        final response = await _api.updateStudySession(sessionId, result);
        print('API response for updateStudySession: $response');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Study session updated successfully')),
          );

          // Session updated successfully - reload the list
          _loadSessions();
        }
      } catch (e) {
        print('Error updating session: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update session: $e')),
          );
        }
      }
    }
  }

  Future<void> _startSession(dynamic session) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => StudyTimerScreen(session: session)),
    );

    if (result != null) {
      final sessionId = session['id']?.toString() ?? session['session_id']?.toString();
      if (sessionId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot update session: missing ID')),
        );
        return;
      }

      try {
        print('Updating completed session $sessionId with data: $result');
        final response = await _api.updateStudySession(sessionId, result);
        print('API response for completed session: $response');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Study session completed successfully!')),
          );
          _loadSessions();
        }
      } catch (e) {
        print('Error updating completed session: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update session: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteSession(dynamic session) async {
    final sessionId = session['id']?.toString() ?? session['session_id']?.toString();
    if (sessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete session: missing ID')),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Study Session'),
        content: const Text('Are you sure you want to delete this study session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Optimistic update: remove from local list immediately
    final originalIndex = _sessions.indexWhere((s) =>
      (s['id']?.toString() ?? s['session_id']?.toString()) == sessionId);

    if (originalIndex != -1) {
      final removedSession = _sessions[originalIndex];
      setState(() {
        _sessions.removeAt(originalIndex);
      });

      try {
        await _api.deleteStudySession(sessionId);

        // Session deleted successfully
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Study session deleted successfully')),
          );
          // Emit event to notify other screens
          _events.emit(AppEventTypes.studySessionDeleted);
        }
      } catch (e) {
        // Rollback on error: add the session back to its original position
        if (mounted) {
          setState(() {
            _sessions.insert(originalIndex, removedSession);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete study session: $e')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session not found in local list')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Sessions'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSessions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('Failed to load study sessions'),
                      const SizedBox(height: 8),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSessions,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _sessions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.school, size: 64, color: Colors.green[200]),
                          const SizedBox(height: 16),
                          const Text(
                            'No study sessions yet',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          const Text('Start your first study session!'),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _addSession,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Study Session'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadSessions,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _sessions.length,
                        itemBuilder: (context, index) {
                          final session = _sessions[index];
                          final subject = session['subject'] ??
                              session['title'] ??
                              session['name'] ??
                              'Study Session';
                          final duration = session['duration'] ??
                              session['duration_minutes'] ??
                              session['length'] ??
                              0;
                          final notes = session['notes'] ??
                              session['description'] ??
                              '';
                          final sessionDate = session['session_date'] ??
                              session['date'] ??
                              session['created_at'] ??
                              '';
                          final formattedDate =
                              sessionDate.toString().split('T').first;

                          final isCompleted = session['is_completed'] ?? false;

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => _editSession(session),
                              child: ExpansionTile(
                                leading: CircleAvatar(
                                  backgroundColor: isCompleted
                                    ? Colors.green[800]
                                    : Colors.green[600],
                                  foregroundColor: Colors.white,
                                  child: Icon(
                                    isCompleted
                                      ? Icons.check_circle
                                      : Icons.school
                                  ),
                                ),
                                title: Text(
                                  subject,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    decoration: isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                    color: isCompleted
                                      ? Colors.grey[600]
                                      : null,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.timer, size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$duration minutes',
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today,
                                            size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          formattedDate,
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(Icons.touch_app,
                                            size: 14, color: Colors.blue[400]),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Tap to edit',
                                          style: TextStyle(
                                            color: Colors.blue[400],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'start':
                                        _startSession(session);
                                        break;
                                      case 'edit':
                                        _editSession(session);
                                        break;
                                      case 'delete':
                                        _deleteSession(session);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    if (!isCompleted)
                                      const PopupMenuItem(
                                        value: 'start',
                                        child: Row(
                                          children: [
                                            Icon(Icons.play_arrow, color: Colors.green),
                                            SizedBox(width: 8),
                                            Text('Start Session'),
                                          ],
                                        ),
                                      ),
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, color: Colors.blue),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (notes.isNotEmpty) ...[
                                          const Text(
                                            'Notes:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(notes),
                                          const SizedBox(height: 16),
                                        ],

                                        // Action buttons
                                        Row(
                                          children: [
                                            if (!isCompleted) ...[
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  onPressed: () => _startSession(session),
                                                  icon: const Icon(Icons.play_arrow),
                                                  label: const Text('Start'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.green[600],
                                                    foregroundColor: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                            ],
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () => _editSession(session),
                                                icon: const Icon(Icons.edit),
                                                label: const Text('Edit'),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.blue[600],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSession,
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

