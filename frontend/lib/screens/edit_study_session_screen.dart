// filepath: frontend/lib/screens/edit_study_session_screen.dart
import 'package:flutter/material.dart';

class EditStudySessionScreen extends StatefulWidget {
  final Map<String, dynamic> session;

  const EditStudySessionScreen({Key? key, required this.session}) : super(key: key);

  @override
  State<EditStudySessionScreen> createState() => _EditStudySessionScreenState();
}

class _EditStudySessionScreenState extends State<EditStudySessionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _subjectCtrl;
  late TextEditingController _descriptionCtrl;
  DateTime? _startTime;
  DateTime? _endTime;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();

    // Initialize with existing session data
    _titleCtrl = TextEditingController(text: widget.session['title'] ?? '');
    _subjectCtrl = TextEditingController(text: widget.session['subject'] ?? '');
    _descriptionCtrl = TextEditingController(text: widget.session['description'] ?? '');
    _isCompleted = widget.session['is_completed'] ?? false;

    // Parse existing dates
    try {
      final startTimeStr = widget.session['start_time'];
      if (startTimeStr != null) {
        _startTime = DateTime.parse(startTimeStr.toString());
      }

      final endTimeStr = widget.session['end_time'];
      if (endTimeStr != null) {
        _endTime = DateTime.parse(endTimeStr.toString());
      }
    } catch (e) {
      print('Error parsing session times: $e');
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subjectCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStartTime() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startTime ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null) {
      if (!mounted) return;

      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_startTime ?? DateTime.now()),
      );

      if (time != null) {
        setState(() {
          _startTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endTime ?? _startTime ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null) {
      if (!mounted) return;

      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_endTime ?? DateTime.now().add(const Duration(hours: 1))),
      );

      if (time != null) {
        setState(() {
          _endTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set both start and end times'))
      );
      return;
    }

    if (_endTime!.isBefore(_startTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time'))
      );
      return;
    }

    final data = {
      'title': _titleCtrl.text.trim(),
      'subject': _subjectCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim(),
      'start_time': _startTime!.toIso8601String(),
      'end_time': _endTime!.toIso8601String(),
      'is_completed': _isCompleted,
    };

    Navigator.of(context).pop(data);
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Not set';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Study Session'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Study Session',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Session Title',
                  hintText: 'What are you studying?',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: Icon(Icons.title, color: Colors.green[600]),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a session title';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _subjectCtrl,
                decoration: InputDecoration(
                  labelText: 'Subject',
                  hintText: 'e.g., Math, Science, History',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: Icon(Icons.subject, color: Colors.green[600]),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a subject';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionCtrl,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Notes about this study session',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: Icon(Icons.notes, color: Colors.green[600]),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 20),

              // Start Time
              InkWell(
                onTap: _pickStartTime,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.green[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Start Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                            Text(_formatDateTime(_startTime), style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // End Time
              InkWell(
                onTap: _pickEndTime,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time_filled, color: Colors.green[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('End Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                            Text(_formatDateTime(_endTime), style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Completion Status
              SwitchListTile(
                title: const Text('Mark as Completed'),
                subtitle: Text(_isCompleted ? 'This session is completed' : 'This session is not completed'),
                value: _isCompleted,
                activeThumbColor: Colors.green[600],
                onChanged: (value) {
                  setState(() {
                    _isCompleted = value;
                  });
                },
              ),

              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _cancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey[600]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Save Session', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
