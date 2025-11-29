// filepath: frontend/lib/screens/study_timer_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';

class StudyTimerScreen extends StatefulWidget {
  final Map<String, dynamic> session;

  const StudyTimerScreen({Key? key, required this.session}) : super(key: key);

  @override
  State<StudyTimerScreen> createState() => _StudyTimerScreenState();
}

class _StudyTimerScreenState extends State<StudyTimerScreen> {
  Timer? _timer;
  DateTime? _startTime;
  DateTime? _endTime;
  Duration _remainingTime = Duration.zero;
  Duration _elapsedTime = Duration.zero;
  bool _isActive = false;
  bool _isCompleted = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _parseSessionTimes();
    _updateTimer();

    // Start the countdown timer
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimer());
  }

  void _parseSessionTimes() {
    try {
      final startTimeStr = widget.session['start_time'];
      final endTimeStr = widget.session['end_time'];

      if (startTimeStr != null && endTimeStr != null) {
        _startTime = DateTime.parse(startTimeStr.toString());
        _endTime = DateTime.parse(endTimeStr.toString());

        print('Session scheduled: ${_startTime!.toLocal()} - ${_endTime!.toLocal()}');
      } else {
        // Fallback: create times for today if not provided
        final now = DateTime.now();
        _startTime = DateTime(now.year, now.month, now.day, now.hour, now.minute);
        _endTime = _startTime!.add(const Duration(hours: 1)); // Default 1 hour session
      }
    } catch (e) {
      print('Error parsing session times: $e');
      // Fallback to current time + 1 hour
      _startTime = DateTime.now();
      _endTime = _startTime!.add(const Duration(hours: 1));
    }
  }

  void _updateTimer() {
    final now = DateTime.now();

    setState(() {
      if (now.isBefore(_startTime!)) {
        // Session hasn't started yet
        _status = 'Session starts in:';
        _remainingTime = _startTime!.difference(now);
        _elapsedTime = Duration.zero;
        _isActive = false;
        _isCompleted = false;
      } else if (now.isAfter(_endTime!)) {
        // Session has ended
        _status = 'Session completed!';
        _remainingTime = Duration.zero;
        _elapsedTime = _endTime!.difference(_startTime!);
        _isActive = false;
        _isCompleted = true;
      } else {
        // Session is active
        _status = 'Time remaining:';
        _remainingTime = _endTime!.difference(now);
        _elapsedTime = now.difference(_startTime!);
        _isActive = true;
        _isCompleted = false;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _completeSession() {
    _timer?.cancel();

    final updatedSession = Map<String, dynamic>.from(widget.session);
    updatedSession['is_completed'] = true;

    if (_startTime != null && _endTime != null) {
      updatedSession['actual_start_time'] = _startTime!.toIso8601String();
      updatedSession['actual_end_time'] = DateTime.now().toIso8601String();
      updatedSession['actual_duration'] = _elapsedTime.inMinutes;
    }

    Navigator.of(context).pop(updatedSession);
  }

  void _extendSession() {
    setState(() {
      _endTime = _endTime!.add(const Duration(minutes: 15)); // Extend by 15 minutes
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session extended by 15 minutes')),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Color _getTimerColor() {
    if (_isCompleted) return Colors.green[600]!;
    if (_isActive) {
      // Change color based on remaining time
      final totalDuration = _endTime!.difference(_startTime!);
      final progress = _elapsedTime.inSeconds / totalDuration.inSeconds;

      if (progress > 0.8) return Colors.red[600]!; // Last 20% - red
      if (progress > 0.6) return Colors.orange[600]!; // 60-80% - orange
      return Colors.blue[600]!; // First 60% - blue
    }
    return Colors.grey[600]!; // Not started
  }

  @override
  Widget build(BuildContext context) {
    final sessionTitle = widget.session['title'] ?? widget.session['subject'] ?? 'Study Session';
    final sessionSubject = widget.session['subject'] ?? '';
    final sessionDescription = widget.session['description'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(sessionTitle),
        backgroundColor: _getTimerColor(),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Session Info Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.school, color: _getTimerColor(), size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            sessionTitle,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (sessionSubject.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.subject, color: Colors.grey[600], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            sessionSubject,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (sessionDescription.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.notes, color: Colors.grey[600], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              sessionDescription,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Session Schedule Info
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Icon(Icons.play_arrow, color: Colors.green[600]),
                        const SizedBox(height: 4),
                        const Text('Start Time', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          _startTime != null ? _formatTime(_startTime!.toLocal()) : '--:--',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(Icons.stop, color: Colors.red[600]),
                        const SizedBox(height: 4),
                        const Text('End Time', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          _endTime != null ? _formatTime(_endTime!.toLocal()) : '--:--',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(Icons.access_time, color: Colors.blue[600]),
                        const SizedBox(height: 4),
                        const Text('Duration', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          _startTime != null && _endTime != null
                              ? _formatDuration(_endTime!.difference(_startTime!))
                              : '--:--',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Main Timer Display
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _status,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _getTimerColor(),
                          width: 6,
                        ),
                      ),
                      child: Text(
                        _formatDuration(_remainingTime),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: _getTimerColor(),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    if (_isActive) ...[
                      Text(
                        'Progress: ${_formatDuration(_elapsedTime)}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Progress bar
                      LinearProgressIndicator(
                        value: _elapsedTime.inSeconds / _endTime!.difference(_startTime!).inSeconds,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(_getTimerColor()),
                      ),
                    ],

                    if (_isCompleted) ...[
                      const SizedBox(height: 16),
                      Icon(
                        Icons.check_circle,
                        size: 48,
                        color: Colors.green[600],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Well done! Session completed.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (_isActive) ...[
                    ElevatedButton.icon(
                      onPressed: _extendSession,
                      icon: const Icon(Icons.add_alarm),
                      label: const Text('Extend\n+15min'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _completeSession,
                      icon: const Icon(Icons.check),
                      label: const Text('Complete\nEarly'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ] else if (_isCompleted) ...[
                    ElevatedButton.icon(
                      onPressed: _completeSession,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Session'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                    ),
                  ] else ...[
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Go Back'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
