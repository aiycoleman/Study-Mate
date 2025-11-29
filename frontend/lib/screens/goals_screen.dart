import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/app_events.dart';
import 'add_goal_screen.dart';
import 'edit_goal_screen.dart';
import 'dart:async';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({Key? key}) : super(key: key);

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final ApiService _api = ApiService();
  final AppEvents _events = AppEvents();
  List<dynamic> _goals = [];
  bool _isLoading = true;
  String? _error;
  late StreamSubscription<String> _eventSubscription;

  @override
  void initState() {
    super.initState();
    _loadGoals();

    // Listen for app events
    _eventSubscription = _events.events.listen((event) {
      if (event == AppEventTypes.goalAdded ||
          event == AppEventTypes.goalDeleted ||
          event == AppEventTypes.goalUpdated) {
        print('Goals screen received event: $event, reloading...');
        _loadGoals();
      }
    });
  }

  @override
  void dispose() {
    _eventSubscription.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Additional fallback: reload goals when screen becomes visible
    if (ModalRoute.of(context)?.isCurrent == true && !_isLoading) {
      print('Goals screen became active, reloading goals as backup...');
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _loadGoals();
      });
    }
  }

  Future<void> _loadGoals() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _api.fetchGoals();
      if (mounted) {
        setState(() {
          _goals = data;
          // Sort goals: uncompleted first, completed at the bottom
          _goals.sort((a, b) {
            final aCompleted = a['is_completed'] ?? a['completed'] ?? false;
            final bCompleted = b['is_completed'] ?? b['completed'] ?? false;

            // If completion status is different, uncompleted comes first
            if (aCompleted != bCompleted) {
              return aCompleted ? 1 : -1; // false (uncompleted) < true (completed)
            }

            // If both have same completion status, sort by target date
            final aDate = a['target_date'] ?? a['due_date'] ?? '';
            final bDate = b['target_date'] ?? b['due_date'] ?? '';
            return aDate.toString().compareTo(bDate.toString());
          });
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addGoal() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const AddGoalScreen()),
    );

    if (result != null) {
      try {
        print('Creating goal with data: $result');
        final response = await _api.createGoal(result);
        print('API response for createGoal: $response');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Goal added successfully')),
          );

          // Extract the created goal from the response
          Map<String, dynamic>? createdGoal;
          if (response.containsKey('goal')) {
            createdGoal = response['goal'] as Map<String, dynamic>?;
          } else if (response.containsKey('data')) {
            createdGoal = response['data'] as Map<String, dynamic>?;
          } else if (response.isNotEmpty) {
            createdGoal = response;
          }

          if (createdGoal != null) {
            // Optimistically add to the local list
            setState(() {
              _goals.insert(0, createdGoal!);
              // Re-sort goals
              _goals.sort((a, b) {
                final aCompleted = a['is_completed'] ?? a['completed'] ?? false;
                final bCompleted = b['is_completed'] ?? b['completed'] ?? false;

                if (aCompleted != bCompleted) {
                  return aCompleted ? 1 : -1;
                }

                final aDate = a['target_date'] ?? a['due_date'] ?? '';
                final bDate = b['target_date'] ?? b['due_date'] ?? '';
                return aDate.toString().compareTo(bDate.toString());
              });
            });
            // Emit event to notify other screens
            _events.emit(AppEventTypes.goalAdded);
          } else {
            // Fallback to reload if we can't extract the goal
            _loadGoals();
          }
        }
      } catch (e) {
        print('Error creating goal: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add goal: $e')),
          );
        }
      }
    }
  }

  Future<void> _editGoal(dynamic goal) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => EditGoalScreen(goal: goal)),
    );

    if (result != null) {
      final goalId = goal['id']?.toString() ?? goal['goal_id']?.toString();
      if (goalId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot edit goal: missing ID')),
        );
        return;
      }

      try {
        print('Updating goal $goalId with data: $result');
        final response = await _api.updateGoal(goalId, result);
        print('API response for updateGoal: $response');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Goal updated successfully')),
          );
          _loadGoals();
          _events.emit(AppEventTypes.goalUpdated);
        }
      } catch (e) {
        print('Error updating goal: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update goal: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleGoalComplete(dynamic goal) async {
    final goalId = goal['id']?.toString() ?? goal['goal_id']?.toString();
    if (goalId == null) return;

    final isCompleted = goal['is_completed'] ?? goal['completed'] ?? false;

    try {
      await _api.updateGoal(goalId, {'is_completed': !isCompleted});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                isCompleted ? 'Goal marked as incomplete' : 'Goal completed!'),
          ),
        );
        _loadGoals();
        // Emit event to notify other screens
        _events.emit(AppEventTypes.goalUpdated);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update goal: $e')),
        );
      }
    }
  }

  Future<void> _deleteGoal(dynamic goal) async {
    final goalId = goal['id']?.toString() ?? goal['goal_id']?.toString();
    if (goalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete goal: missing ID')),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: const Text('Are you sure you want to delete this goal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Optimistic update: remove from local list immediately
    final originalIndex = _goals.indexWhere((g) =>
    (g['id']?.toString() ?? g['goal_id']?.toString()) == goalId);

    if (originalIndex != -1) {
      final removedGoal = _goals[originalIndex];
      setState(() {
        _goals.removeAt(originalIndex);
      });

      try {
        await _api.deleteGoal(goalId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Goal deleted successfully')),
          );
          // Emit event to notify other screens
          _events.emit(AppEventTypes.goalDeleted);
        }
      } catch (e) {
        // Rollback on error: add the goal back to its original position
        if (mounted) {
          setState(() {
            _goals.insert(originalIndex, removedGoal);
            // Re-sort goals after rollback
            _goals.sort((a, b) {
              final aCompleted = a['is_completed'] ?? a['completed'] ?? false;
              final bCompleted = b['is_completed'] ?? b['completed'] ?? false;

              if (aCompleted != bCompleted) {
                return aCompleted ? 1 : -1;
              }

              final aDate = a['target_date'] ?? a['due_date'] ?? '';
              final bDate = b['target_date'] ?? b['due_date'] ?? '';
              return aDate.toString().compareTo(bDate.toString());
            });
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete goal: $e')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goal not found in local list')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGoals,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Failed to load goals'),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadGoals,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : _goals.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag, size: 64, color: Colors.orange[200]),
            const SizedBox(height: 16),
            const Text(
              'No goals yet',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text('Set your first goal!'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addGoal,
              icon: const Icon(Icons.add),
              label: const Text('Add Goal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadGoals,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _goals.length,
          itemBuilder: (context, index) {
            final goal = _goals[index];
            final goalText = goal['goal_text'] ??
                goal['title'] ??
                goal['description'] ??
                'Untitled Goal';
            final targetDate = goal['target_date'] ??
                goal['due_date'] ??
                goal['created_at'] ??
                '';
            final formattedDate =
                targetDate.toString().split('T').first;
            final isCompleted =
                goal['is_completed'] ?? goal['completed'] ?? false;

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _editGoal(goal),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: ListTile(
                    leading: Checkbox(
                      value: isCompleted,
                      onChanged: (_) => _toggleGoalComplete(goal),
                      activeColor: Colors.orange[600],
                    ),
                    title: Text(
                      goalText,
                      style: TextStyle(
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: isCompleted
                            ? Colors.grey[600]
                            : Colors.black,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              'Due: $formattedDate',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.touch_app,
                                size: 14, color: Colors.blue[400]),
                            const SizedBox(width: 4),
                            Text(
                              'Tap to edit',
                              style: TextStyle(
                                color: Colors.blue[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        if (isCompleted) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.check_circle,
                                  size: 14, color: Colors.green[600]),
                              const SizedBox(width: 4),
                              Text(
                                'Completed',
                                style: TextStyle(
                                  color: Colors.green[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _editGoal(goal);
                            break;
                          case 'delete':
                            _deleteGoal(goal);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addGoal,
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
