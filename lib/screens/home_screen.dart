import 'package:flutter/material.dart';
import 'package:aiassistant1/models/task.dart';
import 'package:aiassistant1/services/task_services.dart';
import 'package:aiassistant1/screens/create_task_screen.dart';
import 'package:aiassistant1/screens/calendar_screen.dart';
import 'package:aiassistant1/screens/settings_screen.dart';
import 'package:aiassistant1/screens/ai_task_creation_screen.dart';
import 'package:aiassistant1/screens/voice_task_creation_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('User not logged in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        automaticallyImplyLeading: true,
      ),
      body:
          _selectedIndex == 0
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('User not logged in'));

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
          user.uid,
          filter: TaskViewFilter.completed,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            debugPrint('🔥 Firestore Stream Error: $error');
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
        userId: user.uid,
        isArchived: isArchivedView,
        isReminder: isReminder,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
       if (snapshot.hasError) {
  final error = snapshot.error;
  // Print the error in the console
  debugPrint('🔥 Firestore Stream Error: $error');

  // Optionally, extract and print the "create index" URL
  if (error is FirebaseException &&
      error.plugin == 'cloud_firestore' &&
      error.code == 'failed-precondition') {
    final msg = error.message ?? '';
    final match = RegExp(r'https://console\.firebase\.google\.com[^\s]+')
        .firstMatch(msg);
    if (match != null) {
      debugPrint('👉 Create the missing Firestore index here: ${match.group(0)}');
    }
  }

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
            _showConfirmationDialog(
              title: 'Archive Task',
              content: 'Are you sure you want to archive this task?',
              confirmText: 'Archive',
              onConfirm: () => _taskService.archiveTask(task.id!),
            );
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
