// filepath: lib/screens/google_calendar_settings_screen.dart
// Google Calendar settings screen removed - this file contains empty stub to prevent build errors

import 'package:flutter/material.dart';

class GoogleCalendarSettingsScreen extends StatefulWidget {
  const GoogleCalendarSettingsScreen({Key? key}) : super(key: key);

  @override
  State<GoogleCalendarSettingsScreen> createState() => _GoogleCalendarSettingsScreenState();
}

class _GoogleCalendarSettingsScreenState extends State<GoogleCalendarSettingsScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Calendar Integration'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info,
                size: 64,
                color: Colors.blue,
              ),
              SizedBox(height: 24),
              Text(
                'Google Calendar Integration Removed',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Google Calendar integration has been removed from this application. Your study sessions are managed locally within the app.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
