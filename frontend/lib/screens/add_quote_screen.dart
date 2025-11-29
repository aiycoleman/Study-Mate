import 'package:flutter/material.dart';

class AddQuoteScreen extends StatefulWidget {
  const AddQuoteScreen({Key? key}) : super(key: key);

  @override
  State<AddQuoteScreen> createState() => _AddQuoteScreenState();
}

class _AddQuoteScreenState extends State<AddQuoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quoteController = TextEditingController();

  @override
  void dispose() {
    _quoteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final result = {
      'content': _quoteController.text.trim(), // Backend expects 'content'
    };

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Quote'),
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _quoteController,
                decoration: const InputDecoration(
                  labelText: 'Quote Text',
                  border: OutlineInputBorder(),
                  hintText: 'Enter your motivational quote...',
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the quote text';
                  }
                  if (value.length > 500) {
                    return 'Quote must not exceed 500 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[600],
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Add Quote'),
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

