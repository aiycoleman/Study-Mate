import 'package:flutter/material.dart';

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({Key? key}) : super(key: key);

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _goalCtrl = TextEditingController();
  DateTime? _targetDate;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (d != null) setState(() => _targetDate = d);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_targetDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please pick a target date')));
      return;
    }

    // Format date as RFC3339 with time and timezone (backend expects full datetime)
    // Create a DateTime with the selected date at midnight UTC
    final dateTime = DateTime.utc(
      _targetDate!.year,
      _targetDate!.month,
      _targetDate!.day,
      0,
      0,
      0,
    );
    final formattedDate = dateTime.toIso8601String();

    // Backend only accepts goal_text and target_date (is_completed is set to false by default)
    final data = {
      'goal_text': _goalCtrl.text.trim(),
      'target_date': formattedDate,
    };

    print('Submitting goal data: $data'); // Debug print
    Navigator.of(context).pop(data);
  }

  @override
  void dispose() {
    _goalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String dateLabel = _targetDate == null ? 'Select date' : _targetDate!.toLocal().toString().split(' ')[0];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Goal'),
        backgroundColor: Colors.blue[600],
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _goalCtrl,
                decoration: const InputDecoration(labelText: 'Goal'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Target Date'),
                subtitle: Text(dateLabel),
                onTap: _pickDate,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Goals are created as active. Mark them as completed from the Goals screen.',
                        style: TextStyle(color: Colors.blue[900], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(onPressed: _submit, child: const Text('Add')),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
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

