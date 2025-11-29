// filepath: frontend/lib/screens/edit_goal_screen.dart
import 'package:flutter/material.dart';

class EditGoalScreen extends StatefulWidget {
  final Map<String, dynamic> goal;

  const EditGoalScreen({Key? key, required this.goal}) : super(key: key);

  @override
  State<EditGoalScreen> createState() => _EditGoalScreenState();
}

class _EditGoalScreenState extends State<EditGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _goalCtrl;
  DateTime? _targetDate;

  @override
  void initState() {
    super.initState();

    // Initialize with existing goal data
    final goalText = widget.goal['goal_text'] ??
                    widget.goal['title'] ??
                    widget.goal['description'] ?? '';
    _goalCtrl = TextEditingController(text: goalText);

    // Parse existing target date
    final targetDateStr = widget.goal['target_date'] ??
                         widget.goal['due_date'] ?? '';
    if (targetDateStr.isNotEmpty) {
      try {
        _targetDate = DateTime.parse(targetDateStr.toString().split('T')[0]);
      } catch (e) {
        print('Error parsing target date: $e');
      }
    }
  }

  @override
  void dispose() {
    _goalCtrl.dispose();
    super.dispose();
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _targetDate = picked;
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_targetDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a target date'))
      );
      return;
    }

    // Format date as RFC3339 with time and timezone
    final dateTime = DateTime.utc(
      _targetDate!.year,
      _targetDate!.month,
      _targetDate!.day,
      0,
      0,
      0,
    );
    final formattedDate = dateTime.toIso8601String();

    final data = {
      'goal_text': _goalCtrl.text.trim(),
      'target_date': formattedDate,
    };

    Navigator.of(context).pop(data);
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Goal'),
        backgroundColor: Colors.orange[600],
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit your goal',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _goalCtrl,
                decoration: InputDecoration(
                  labelText: 'Goal Description',
                  hintText: 'What do you want to achieve?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.flag, color: Colors.orange[600]),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a goal description';
                  }
                  if (value.trim().length < 3) {
                    return 'Goal must be at least 3 characters long';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.orange[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Target Date',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _targetDate != null
                                  ? '${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}'
                                  : 'Select target date',
                              style: TextStyle(
                                fontSize: 16,
                                color: _targetDate != null
                                    ? Colors.black
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Save Goal',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
