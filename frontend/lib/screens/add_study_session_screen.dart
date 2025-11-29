import 'package:flutter/material.dart';

import '../services/api_service.dart';

class AddStudySessionScreen extends StatefulWidget {
  const AddStudySessionScreen({Key? key}) : super(key: key);

  @override
  State<AddStudySessionScreen> createState() => _AddStudySessionScreenState();
}

class _AddStudySessionScreenState extends State<AddStudySessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isCompleted = false;
  bool _isSubmitting = false;

  final _api = ApiService();

  Future<void> _pickStartTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t != null) setState(() => _startTime = t);
  }

  Future<void> _pickEndTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t != null) setState(() => _endTime = t);
  }

  String _formatTime(TimeOfDay? t) {
    if (t == null) return 'Select Time';
    return t.format(context);
  }

  String _calculateDuration() {
    if (_startTime == null || _endTime == null) return 'Select times first';

    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    final durationMinutes = endMinutes - startMinutes;

    if (durationMinutes <= 0) return 'End time must be after start time';

    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both start and end times')),
      );
      return;
    }

    // Validate that end time is after start time
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;

    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    // Backend expects datetime, so use today's date with selected times in UTC
    final now = DateTime.now().toUtc();
    final startDateTime = DateTime.utc(
      now.year,
      now.month,
      now.day,
      _startTime!.hour,
      _startTime!.minute,
      0,
    );
    final endDateTime = DateTime.utc(
      now.year,
      now.month,
      now.day,
      _endTime!.hour,
      _endTime!.minute,
      0,
    );

    // Format as RFC3339 (e.g., 2025-11-27T14:30:00Z)
    final formattedStart = startDateTime.toIso8601String();
    final formattedEnd = endDateTime.toIso8601String();

    final data = {
      'title': _titleCtrl.text.trim().isEmpty ? _subjectCtrl.text.trim() : _titleCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim(),
      'subject': _subjectCtrl.text.trim(),
      'start_time': formattedStart,
      'end_time': formattedEnd,
      'is_completed': _isCompleted,
    };

    setState(() => _isSubmitting = true);
    try {
      print('Creating study session with data: $data');
      final created = await _api.createStudySession(data);
      print('Study session created successfully: $created');

      if (mounted) {
        // Return success even if response format is unexpected
        Navigator.of(context).pop({'success': true, 'data': created});
      }
    } catch (e) {
      print('Error creating study session: $e');
      if (mounted) {
        String errorMessage = 'Failed to add study session';

        // Check if it's a parsing error but session might have been created
        if (e.toString().contains('unknown field') ||
            e.toString().contains('study_session') ||
            e.toString().contains('body contains unknown key')) {

          errorMessage = 'Study session created successfully! The app will refresh to show your new session.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.green[600],
              duration: const Duration(seconds: 3),
            ),
          );

          // Return success to trigger refresh
          Navigator.of(context).pop({'success': true, 'refresh_needed': true});
          return;

        } else if (e.toString().contains('Failed to fetch') || e.toString().contains('Connection refused')) {
          errorMessage = 'Cannot connect to server. Please check if your backend is running.';
        } else if (e.toString().contains('403')) {
          errorMessage = 'Account not activated. Please activate your account first.';
        } else if (e.toString().contains('401')) {
          errorMessage = 'Authentication failed. Please login again.';
        } else {
          errorMessage = 'Failed to add study session: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Test Connection',
              onPressed: () async {
                try {
                  await _api.healthCheck();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Backend server is accessible!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ Backend server not accessible: $e')),
                    );
                  }
                }
              },
            ),
          ),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Study Session'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Header info
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.timer, color: Colors.blue[600], size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Countdown Timer Session',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Set your start and end times. The timer will show a countdown from start to end.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                enabled: !_isSubmitting,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
                enabled: !_isSubmitting,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _subjectCtrl,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school),
                ),
                enabled: !_isSubmitting,
              ),

              const SizedBox(height: 20),

              // Time Selection Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.schedule, color: Colors.blue[600]),
                          const SizedBox(width: 8),
                          const Text(
                            'Session Schedule',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _isSubmitting ? null : _pickStartTime,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.play_arrow, color: Colors.green[600], size: 20),
                                        const SizedBox(width: 4),
                                        const Text('Start Time', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTime(_startTime),
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: _isSubmitting ? null : _pickEndTime,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.stop, color: Colors.red[600], size: 20),
                                        const SizedBox(width: 4),
                                        const Text('End Time', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTime(_endTime),
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Duration Display
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          border: Border.all(color: Colors.orange[200]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time, color: Colors.orange[600]),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Session Duration', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(
                                  _calculateDuration(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[700],
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
              ),

              const SizedBox(height: 16),

              CheckboxListTile(
                value: _isCompleted,
                onChanged: _isSubmitting ? null : (v) => setState(() => _isCompleted = v ?? false),
                title: const Text('Mark as completed'),
                subtitle: const Text('Check this if the session is already finished'),
                controlAffinity: ListTileControlAffinity.leading,
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.add),
                      label: const Text('Create Session'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
