import 'package:flutter/material.dart';
import 'package:aiassistant1/models/task.dart';
import 'package:aiassistant1/services/task_services.dart';
import 'package:aiassistant1/services/simple_notification_service.dart';
import 'package:aiassistant1/screens/create_task_screen.dart';
import 'package:aiassistant1/screens/calendar_screen.dart';
import 'package:aiassistant1/screens/settings_screen.dart';
import 'package:aiassistant1/screens/ai_task_creation_screen.dart';
import 'package:aiassistant1/screens/voice_task_creation_screen.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

enum TaskFilter { all, tasks, reminders, completed, archived }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  TaskFilter _currentFilter = TaskFilter.all;

  void _onDrawerItemTap(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pop(context);
  }

  void _onFilterSelected(TaskFilter filter) {
    setState(() {
      _currentFilter = filter;
      _selectedIndex = 0;
    });
    Navigator.pop(context);
  }

  String _getAppBarTitle() {
    if (_selectedIndex == 1) return 'Calendar';
    if (_selectedIndex == 2) return 'Settings';

    switch (_currentFilter) {
      case TaskFilter.all:
        return 'All Active';
      case TaskFilter.tasks:
        return 'Active Tasks';
      case TaskFilter.reminders:
        return 'Active Reminders';
      case TaskFilter.completed:
        return 'Completed Tasks';
      case TaskFilter.archived:
        return 'Archived';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Auth removed for demo release – always show app

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        automaticallyImplyLeading: true,
      ),
      body: _selectedIndex == 0
          ? TasksView(key: ValueKey(_currentFilter), filter: _currentFilter)
          : _selectedIndex == 1
          ? const CalendarScreen()
          : const SettingsScreen(),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: const Text(
                'HelpME',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            // Task Filters
            ListTile(
              leading: const Icon(Icons.inbox_outlined),
              title: const Text('All Active'),
              selected: _selectedIndex == 0 && _currentFilter == TaskFilter.all,
              onTap: () => _onFilterSelected(TaskFilter.all),
            ),
            ListTile(
              leading: const Icon(Icons.task_alt_outlined),
              title: const Text('Active Tasks'),
              selected:
                  _selectedIndex == 0 && _currentFilter == TaskFilter.tasks,
              onTap: () => _onFilterSelected(TaskFilter.tasks),
            ),
            ListTile(
              leading: const Icon(Icons.alarm),
              title: const Text('Active Reminders'),
              selected:
                  _selectedIndex == 0 && _currentFilter == TaskFilter.reminders,
              onTap: () => _onFilterSelected(TaskFilter.reminders),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Completed Tasks'),
              selected:
                  _selectedIndex == 0 && _currentFilter == TaskFilter.completed,
              onTap: () => _onFilterSelected(TaskFilter.completed),
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('Archived'),
              selected:
                  _selectedIndex == 0 && _currentFilter == TaskFilter.archived,
              onTap: () => _onFilterSelected(TaskFilter.archived),
            ),
            const Divider(),
            // Navigation
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Calendar'),
              selected: _selectedIndex == 1,
              onTap: () => _onDrawerItemTap(1),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              selected: _selectedIndex == 2,
              onTap: () => _onDrawerItemTap(2),
            ),
            const Divider(),
          ],
        ),
      ),
      floatingActionButton: _selectedIndex == 0
          ? SpeedDial(
              icon: Icons.add,
              activeIcon: Icons.close,
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              spacing: 16,
              spaceBetweenChildren: 16,
              overlayColor: Colors.black,
              overlayOpacity: 0.5,
              elevation: 8,
              animationCurve: Curves.elasticInOut,
              animationDuration: const Duration(milliseconds: 300),
              children: [
                SpeedDialChild(
                  child: const Icon(Icons.edit),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  label: 'Manual Task',
                  labelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateTaskScreen(),
                      ),
                    );
                  },
                ),
                SpeedDialChild(
                  child: const Icon(Icons.message),
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  label: 'Quick AI Task',
                  labelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AITaskCreationScreen(),
                      ),
                    );
                    
                    // Handle returned task data from AI creation
                    if (result != null && result is Map<String, dynamic>) {
                      // Navigate to CreateTaskScreen with the AI-generated data
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateTaskScreen(
                            aiGeneratedData: result,
                          ),
                        ),
                      );
                      
                      // If task was created successfully, the StreamBuilder will refresh automatically
                    }
                  },
                ),
                SpeedDialChild(
                  child: const Icon(Icons.mic),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  label: 'Voice Task',
                  labelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VoiceTaskCreationScreen(),
                      ),
                    );
                    // Refresh if task was created
                    if (result == true) {
                      // The StreamBuilder will automatically refresh
                    }
                  },
                ),
              ],
            )
          : null,
    );
  }
}

class TasksView extends StatefulWidget {
  final TaskFilter filter;

  const TasksView({super.key, required this.filter});

  @override
  State<TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<TasksView> {
  final TaskService _taskService = TaskService();

  void _toggleTaskCompletion(BuildContext context, Task task) async {
    final newCompletionStatus = !task.isCompleted;
    final taskTitle = task.title;

    // Update the task immediately for responsive UI
    try {
      await _taskService.updateTask(
        task.copyWith(isCompleted: newCompletionStatus),
      );

      if (!context.mounted) return;

      // Show appropriate snackbar message
      final snackBar = SnackBar(
        content: Row(
          children: [
            Icon(
              newCompletionStatus ? Icons.check_circle : Icons.radio_button_unchecked,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                newCompletionStatus 
                  ? 'Task marked as completed' 
                  : 'Task marked as incomplete',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: newCompletionStatus ? Colors.green[600] : Colors.orange[600],
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.fixed,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () async {
            // Undo the completion toggle
            try {
              await _taskService.updateTask(
                task.copyWith(isCompleted: task.isCompleted),
              );
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(
                          Icons.undo,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Changes undone for "$taskTitle"',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.blue[600],
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.fixed,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to undo: $e'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            }
          },
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to update task: $e',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red[600],
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.fixed,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const String demoUserId = 'demo_user';

    bool isArchivedView = widget.filter == TaskFilter.archived;
    bool isCompletedView = widget.filter == TaskFilter.completed;
    bool? isReminder;
    if (widget.filter == TaskFilter.tasks) {
      isReminder = false;
    } else if (widget.filter == TaskFilter.reminders) {
      isReminder = true;
    }

    // For completed tasks, we need to use the getTasks method instead of getTasksStream
    if (isCompletedView) {
      return StreamBuilder<List<Task>>(
        stream: _taskService.getTasks(
          demoUserId,
          filter: TaskViewFilter.completed,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return Center(child: Text('Error: $error'));
          }

          final tasks = snapshot.data ?? [];
          if (tasks.isEmpty) {
            return const Center(child: Text('No completed tasks yet.'));
          }

          final groupedTasks = _groupTasks(tasks);

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: groupedTasks.length,
            itemBuilder: (context, index) {
              final date = groupedTasks.keys.elementAt(index);
              final tasksForDate = groupedTasks[date]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      DateFormat('EEEE, MMM d, yyyy').format(date),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  ...tasksForDate.map(
                    (task) => _buildTaskListItem(context, task),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    return StreamBuilder<List<Task>>(
      stream: _taskService.getTasksStream(
        userId: demoUserId,
        isArchived: isArchivedView,
        isReminder: isReminder,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          return Center(child: Text('Error: $error'));
        }

        final tasks = snapshot.data ?? [];
        if (tasks.isEmpty) {
          return const Center(child: Text('No tasks here.'));
        }

        final groupedTasks = _groupTasks(tasks);

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          itemCount: groupedTasks.length,
          itemBuilder: (context, index) {
            final date = groupedTasks.keys.elementAt(index);
            final tasksForDate = groupedTasks[date]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    DateFormat('EEEE, MMM d, yyyy').format(date),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                ...tasksForDate.map(
                  (task) => _buildTaskListItem(context, task),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Map<DateTime, List<Task>> _groupTasks(List<Task> tasks) {
    final Map<DateTime, List<Task>> grouped = {};
    for (final task in tasks) {
      final date = DateTime(
        task.dueDate.year,
        task.dueDate.month,
        task.dueDate.day,
      );
      if (grouped[date] == null) grouped[date] = [];
      grouped[date]!.add(task);
    }
    return grouped;
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'academics':
        return Colors.blue;
      case 'social':
        return Colors.purple;
      case 'personal':
        return Colors.green;
      case 'health':
        return Colors.red;
      case 'work':
        return Colors.orange;
      case 'finance':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
    required VoidCallback onConfirm,
  }) async {
    return showDialog<void>(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: Text(
                  confirmText,
                  style: const TextStyle(color: Colors.red),
                ),
                onPressed: () {
                  onConfirm();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
    );
  }

  Future<void> _showTaskOptionsDialog(Task task) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.task_alt,
                color: Colors.blue,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Task Options',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What would you like to do with this task?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                '${task.title}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),
            
            // Archive option
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
                _showConfirmationDialog(
                  title: 'Archive Task',
                  content: 'Are you sure you want to archive "${task.title}"? You can restore it later from the archived section.',
                  confirmText: 'Archive',
                  onConfirm: () async {
                    try {
                      await _taskService.archiveTask(task.id!);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.archive, color: Colors.white, size: 20),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Task archived successfully',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.orange[600],
                            duration: const Duration(seconds: 3),
                            behavior: SnackBarBehavior.fixed,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to archive task: $e'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.fixed,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                          ),
                        );
                      }
                    }
                  },
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.archive_outlined,
                      color: Colors.orange[600],
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Archive Task',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[700],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Move to archived section',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.orange[600],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Delete option
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
                _showConfirmationDialog(
                  title: 'Delete Task',
                  content: 'Are you sure you want to permanently delete "${task.title}"? This action cannot be undone.',
                  confirmText: 'Delete',
                  onConfirm: () async {
                    try {
                      await _taskService.deleteTaskPermanently(task.id!);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.delete_forever, color: Colors.white, size: 20),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Task deleted permanently',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.red[600],
                            duration: const Duration(seconds: 3),
                            behavior: SnackBarBehavior.fixed,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to delete task: $e'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.fixed,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                          ),
                        );
                      }
                    }
                  },
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_forever_outlined,
                      color: Colors.red[600],
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delete Task',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.red[700],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Delete permanently',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.red[600],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Cancel button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskListItem(BuildContext context, Task task) {
    bool isArchivedView = widget.filter == TaskFilter.archived;
    bool isCompletedView = widget.filter == TaskFilter.completed;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      elevation: 1.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(8.0),
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateTaskScreen(task: task),
              ),
            ),
        onLongPress: () {
          if (isArchivedView) {
            _showConfirmationDialog(
              title: 'Delete Task',
              content: 'Are you sure you want to permanently delete this task?',
              confirmText: 'Delete',
              onConfirm: () => _taskService.deleteTaskPermanently(task.id!),
            );
          } else if (isCompletedView) {
            _showConfirmationDialog(
              title: 'Archive Task',
              content: 'Are you sure you want to archive this completed task?',
              confirmText: 'Archive',
              onConfirm: () => _taskService.archiveTask(task.id!),
            );
          } else {
            // Show both archive and delete options for active tasks
            _showTaskOptionsDialog(task);
          }
        },
        child: Row(
          children: [
            Container(
              width: 5.0,
              height: 65.0,
              decoration: BoxDecoration(
                color: _getCategoryColor(task.category),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8.0),
                  bottomLeft: Radius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: () {
                if (!isArchivedView) {
                  _toggleTaskCompletion(context, task);
                }
              },
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child:
                    task.isCompleted
                        ? Icon(Icons.check_circle, color: Colors.green.shade600)
                        : const Icon(
                          Icons.radio_button_unchecked_outlined,
                          color: Colors.grey,
                        ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 8.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        decoration:
                            task.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                        color: task.isCompleted ? Colors.grey : null,
                      ),
                    ),
                    if (task.description != null &&
                        task.description!.isNotEmpty)
                      Text(
                        task.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (task.isReminder && !isCompletedView && !isArchivedView)
                    const Icon(
                      Icons.alarm,
                      size: 16.0,
                      color: Colors.blueAccent,
                    ),
                  if (isCompletedView || isArchivedView) 
                    _buildTaskActions(task, isCompletedView, isArchivedView),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskActions(Task task, bool isCompletedView, bool isArchivedView) {
    if (isCompletedView) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Undo button - mark as incomplete
          InkWell(
            onTap: () async {
              try {
                await _taskService.updateTask(
                  task.copyWith(isCompleted: false),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.undo, color: Colors.white, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Task moved back to active',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.blue[600],
                      duration: const Duration(seconds: 3),
                      behavior: SnackBarBehavior.fixed,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update task: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.fixed,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                    ),
                  );
                }
              }
            },
            customBorder: const CircleBorder(),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.undo,
                size: 20,
                color: Colors.blue[600],
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Delete button - permanent delete
          InkWell(
            onTap: () {
              _showConfirmationDialog(
                title: 'Delete Task',
                content: 'Are you sure you want to permanently delete this completed task? This action cannot be undone.',
                confirmText: 'Delete',
                onConfirm: () async {
                  try {
                    await _taskService.deleteTaskPermanently(task.id!);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check, color: Colors.white, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Task deleted permanently',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.red[600],
                          duration: const Duration(seconds: 3),
                          behavior: SnackBarBehavior.fixed,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to delete task: $e'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.fixed,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                        ),
                      );
                    }
                  }
                },
              );
            },
            customBorder: const CircleBorder(),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.delete_forever,
                size: 20,
                color: Colors.red[600],
              ),
            ),
          ),
        ],
      );
    } else if (isArchivedView) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Unarchive button
          InkWell(
            onTap: () async {
              try {
                await _taskService.unarchiveTask(task.id!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.unarchive, color: Colors.white, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Task unarchived successfully',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.green[600],
                      duration: const Duration(seconds: 3),
                      behavior: SnackBarBehavior.fixed,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to unarchive task: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.fixed,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                    ),
                  );
                }
              }
            },
            customBorder: const CircleBorder(),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.unarchive,
                size: 20,
                color: Colors.green[600],
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Delete button - permanent delete
          InkWell(
            onTap: () {
              _showConfirmationDialog(
                title: 'Delete Task',
                content: 'Are you sure you want to permanently delete this archived task? This action cannot be undone.',
                confirmText: 'Delete',
                onConfirm: () async {
                  try {
                    await _taskService.deleteTaskPermanently(task.id!);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check, color: Colors.white, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Task deleted permanently',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.red[600],
                          duration: const Duration(seconds: 3),
                          behavior: SnackBarBehavior.fixed,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to delete task: $e'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.fixed,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                        ),
                      );
                    }
                  }
                },
              );
            },
            customBorder: const CircleBorder(),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.delete_forever,
                size: 20,
                color: Colors.red[600],
              ),
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
