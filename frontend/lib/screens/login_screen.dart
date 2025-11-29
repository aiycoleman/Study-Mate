// filepath: frontend/lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final ok = await auth.login(username, password);
      if (ok) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Check if it's a connection issue or credentials issue
        final errorMsg = auth.lastError ?? 'Login failed';
        if (errorMsg.contains('Network') || errorMsg.contains('Connection') ||
            errorMsg.contains('SocketException') || errorMsg.contains('TimeoutException')) {
          setState(() => _error = 'Backend server is not responding at localhost:4000. Please check if the server is running.');
        } else if (errorMsg.contains('401') || errorMsg.contains('Invalid credentials')) {
          setState(() => _error = 'Invalid credentials. Please check your email/username and password.\n\nNote: Account must be activated. Check your email for activation token.');
        } else {
          setState(() => _error = errorMsg);
        }
      }
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('SocketException') || errorStr.contains('Connection') ||
          errorStr.contains('Network') || errorStr.contains('TimeoutException')) {
        setState(() => _error = 'Cannot connect to backend server at localhost:4000.\n\nMake sure the backend is running:\n• In VM: make run/api\n• Or on Windows: go run ./cmd/api');
      } else {
        setState(() => _error = errorStr);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _testBackendConnection() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = AuthService();
      final isConnected = await authService.testConnection();

      if (isConnected) {
        setState(() {
          _error = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Backend server is reachable!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _error = 'Backend server is not responding at localhost:4000. Please check if the server is running.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection test failed: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // // Debug: Show API URL
              // Container(
              //   padding: const EdgeInsets.all(8),
              //   decoration: BoxDecoration(
              //     color: Colors.blue.shade100,
              //     borderRadius: BorderRadius.circular(8),
              //   ),
              //   child: Text(
              //     'API: $apiBaseUrl',
              //     style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              //   ),
              // ),
              const SizedBox(height: 16),
              const Text(
                'Welcome Back',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _error!.contains('backend server') || _error!.contains('Connection')
                                  ? 'Connection Error'
                                  : 'Login Failed',
                              style: TextStyle(
                                color: Colors.red[800],
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _error!,
                              style: TextStyle(color: Colors.red[700], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Text('Login'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                  Navigator.pushReplacementNamed(context, '/signup');
                },
                child: const Text('Don\'t have an account? Sign up'),
              ),
              const SizedBox(height: 24),
              // Debug connectivity button
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _testBackendConnection,
                icon: const Icon(Icons.network_check),
                label: const Text('Test Backend Connection'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
