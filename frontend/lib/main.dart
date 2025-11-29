// filepath: frontend/lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// App screens
import 'screens/home_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/activate_account_screen.dart';

// Providers
import 'providers/auth_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthProvider>(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'Study Mate',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthGate(),
          '/signup': (context) => const SignUpScreen(),
          '/login': (context) => const LoginScreen(),
          '/activate': (context) => const ActivateAccountScreen(),
          '/home': (context) => const HomeScreen(),
          '/quotes': (context) => const HomeScreen(),
          '/goals': (context) => const HomeScreen(),
          '/study-sessions': (context) => const HomeScreen(),
          '/profile': (context) => const HomeScreen(),
        },
      ),
    );
  }
}

/// Shows a loading state while provider initializes,
/// then redirects to signup/login or home based on auth state.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (!auth.initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!auth.isAuthenticated) {
      // Start on signup but keep login route available
      return const SignUpScreen();
    }

    return const HomeScreen();
  }
}
