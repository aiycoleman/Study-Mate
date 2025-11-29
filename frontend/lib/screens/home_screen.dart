import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/weather_service.dart';
import '../models/weather_model.dart';
import '../services/quotes_service.dart';
import 'quotes_screen.dart' as quotes;
import 'goals_screen.dart' as goals;
import 'study_sessions_screen.dart' as study;
import 'profile_screen.dart' as profile;
import 'add_study_session_screen.dart';
import 'add_goal_screen.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isBackendConnected = false;
  bool _isCheckingConnection = true;
  final ApiService _api = ApiService();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const DashboardTab(),
      const quotes.QuotesScreen(),
      const goals.GoalsScreen(),
      const study.StudySessionsScreen(),
      const profile.ProfileScreen(),
    ];
    _checkBackendConnection();
  }

  Future<void> _checkBackendConnection() async {
    setState(() {
      _isCheckingConnection = true;
    });

    try {
      await _api.healthCheck();
      if (mounted) {
        setState(() {
          _isBackendConnected = true;
          _isCheckingConnection = false;
        });
      }
    } catch (e) {
      print('Backend connection failed: $e');
      if (mounted) {
        setState(() {
          _isBackendConnected = false;
          _isCheckingConnection = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingConnection) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Connecting to server...'),
            ],
          ),
        ),
      );
    }

    if (!_isBackendConnected) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Cannot connect to server',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Make sure your backend is running on\nlocalhost:4000',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isCheckingConnection = true;
                  });
                  _checkBackendConnection();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue[600],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.format_quote),
            label: 'Quotes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag),
            label: 'Goals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Study',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class DashboardTab extends StatefulWidget {
  const DashboardTab({Key? key}) : super(key: key);

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final ApiService _api = ApiService();

  // Weather and quote services/state
  final WeatherService _weatherService = WeatherService();
  final QuotesService _quotesService = QuotesService();
  WeatherData? _weatherData;
  Map<String, dynamic>? _weatherQuote;
  bool _weatherLoading = true;

  List<dynamic> _studySessions = [];
  List<dynamic> _goals = [];
  List<dynamic> _quotes = [];
  double _totalStudyHours = 0.0;

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _weatherLoading = true;
    });

    try {
      // Load all data concurrently including weather + quote
      final results = await Future.wait([
        _api.fetchStudySessions().catchError((e) => <dynamic>[]),
        _api.fetchGoals().catchError((e) => <dynamic>[]),
        _api.fetchQuotes().catchError((e) => <dynamic>[]),
        _api.getTotalStudyHours().catchError((e) => 0.0),
      ]);

      // Fetch weather and quote separately to avoid type issues with catchError returning null
      WeatherData? weather;
      Map<String, dynamic>? quote;
      try {
        weather = await _weatherService.getCurrentWeather();
      } catch (_) {
        weather = null;
      }
      try {
        quote = await _quotesService.getDailyMotivationalQuote();
      } catch (_) {
        quote = null;
      }

      if (mounted) {
        // // debug prints so you can see the results in the console when running
        // debugPrint('Dashboard: studySessions=${(results[0] as List).length}, goals=${(results[1] as List).length}, quotes=${(results[2] as List).length}, totalHours=${results[3]}');
        // debugPrint('Dashboard: weather=${weather != null}, quote=${quote != null}');
        setState(() {
          _studySessions = results[0] as List<dynamic>;
          _goals = results[1] as List<dynamic>;
          _quotes = results[2] as List<dynamic>;
          _totalStudyHours = results[3] as double;
          _weatherData = weather;
          _weatherQuote = quote;
          _isLoading = false;
          _weatherLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _weatherLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Mate Dashboard'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading dashboard data...'),
          ],
        ),
      )
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Failed to load dashboard data'),
            const SizedBox(height: 8),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboardData,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back!!',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ready to continue your learning journey?',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Weather + quote card (moved up for visibility)
              Card(
                color: Colors.blue.shade50,
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(8)),
                            child: Text(_weatherData != null ? _weatherService.getWeatherIcon(_weatherData!.icon) : '🌤️', style: const TextStyle(fontSize: 28)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Belize Weather', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(_weatherData != null ? '${_weatherData!.temperature.toStringAsFixed(1)}°C — ${_weatherData!.description}' : 'No weather data', style: Theme.of(context).textTheme.bodyLarge),
                                Text(_weatherData != null ? _weatherData!.cityName : '', style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(_weatherService.getFormattedTime(), style: Theme.of(context).textTheme.bodyLarge),
                              const SizedBox(height: 4),
                              Text(_weatherLoading ? 'Loading...' : 'Updated', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _weatherQuote != null
                            ? '"${_weatherQuote!['content']}" — ${_weatherQuote!['author'] ?? ''}'
                            : (_weatherData != null ? _weatherService.getStudyMotivation(_weatherData!.description) : 'Another great day to learn something new!'),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
                      ),
                      if (kDebugMode) ...[
                        const SizedBox(height: 8),
                        // Text('debug: weatherLoading=$_weatherLoading, weatherData=${_weatherData != null}, quote=${_weatherQuote != null}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Quick Stats',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Study Sessions',
                      _studySessions.length.toString(),
                      Icons.school,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Goals',
                      _goals.length.toString(),
                      Icons.flag,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Quotes',
                      _quotes.length.toString(),
                      Icons.format_quote,
                      Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Hours Studied',
                      _totalStudyHours.toStringAsFixed(1),
                      Icons.timer,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      context,
                      'Start Study Session',
                      Icons.add,
                      Colors.green,
                      _navigateToAddStudySession,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      context,
                      'Add Goal',
                      Icons.add,
                      Colors.blue,
                      _navigateToAddGoal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_goals.isNotEmpty) ...[
                Text(
                  'Recent Goals',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _goals.length > 3 ? 3 : _goals.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final goal = _goals[index];
                    final goalText = goal['goal_text'] ?? goal['title'] ?? goal['description'] ?? 'Untitled Goal';
                    final targetDate = goal['target_date'] ?? goal['due_date'] ?? goal['created_at'] ?? '';
                    final formattedDate = targetDate.toString().split('T').first;

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.flag, color: Colors.orange),
                        title: Text(goalText),
                        subtitle: Text('Due: $formattedDate'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteGoal(goal),
                        ),
                      ),
                    );
                  },
                ),
                if (_goals.length > 3)
                  TextButton(
                    onPressed: () {
                      final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                      homeState?.setState(() {
                        homeState._currentIndex = 2;
                      });
                    },
                    child: Text('View all ${_goals.length} goals'),
                  ),
                const SizedBox(height: 12),
              ],
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[600]),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Connected to backend server'),
                      ),
                      Text(
                        'localhost:4000',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToAddStudySession() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const AddStudySessionScreen()),
    );
    if (result != null) {
      try {
        await _api.createStudySession(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Study session added successfully')),
          );
          _loadDashboardData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add study session: $e')),
          );
        }
      }
    }
  }

  Future<void> _navigateToAddGoal() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const AddGoalScreen()),
    );
    if (result != null) {
      try {
        await _api.createGoal(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Goal added successfully')),
          );
          _loadDashboardData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add goal: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteGoal(Map<String, dynamic> goal) async {
    final goalId = goal['id']?.toString() ?? goal['goal_id']?.toString();
    if (goalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete goal: missing ID')),
      );
      return;
    }

    try {
      await _api.deleteGoal(goalId);
      await _loadDashboardData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete goal: $e')),
        );
      }
    }
  }
}
