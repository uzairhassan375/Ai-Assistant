import 'package:flutter/material.dart';
import 'package:aiassistant1/models/task.dart';
import 'package:aiassistant1/services/task_services.dart';
import 'package:aiassistant1/screens/create_task_screen.dart';
import 'package:aiassistant1/screens/calendar_screen.dart';
import 'package:aiassistant1/screens/settings_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

enum TaskFilter { all, tasks, reminders, archived }

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
      floatingActionButton:
          _selectedIndex == 0
              ? FloatingActionButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateTaskScreen(),
                    ),
                  );
                  // The StreamBuilder will automatically refresh when new data is available
                },
                child: const Icon(Icons.add),
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('User not logged in'));

    bool isArchivedView = widget.filter == TaskFilter.archived;
    bool? isReminder;
    if (widget.filter == TaskFilter.tasks) {
      isReminder = false;
    } else if (widget.filter == TaskFilter.reminders) {
      isReminder = true;
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
                  _taskService.updateTask(
                    task.copyWith(isCompleted: !task.isCompleted),
                  );
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
              child:
                  task.isReminder
                      ? const Icon(
                        Icons.alarm,
                        size: 16.0,
                        color: Colors.blueAccent,
                      )
                      : null,
            ),
          ],
        ),
      ),
    );
  }
}
