import 'package:flutter/material.dart';
import 'package:aiassistant1/models/task.dart';
import 'package:aiassistant1/services/task_services.dart';
import 'package:aiassistant1/screens/create_task_screen.dart';
import 'package:aiassistant1/screens/calendar_screen.dart';
import 'package:aiassistant1/screens/settings_screen.dart';
import 'package:aiassistant1/screens/ai_task_creation_screen.dart';
import 'package:aiassistant1/screens/voice_task_creation_screen.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: isSelected 
          ? const LinearGradient(
              colors: [Colors.white, Colors.white],
            )
          : null,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isSelected 
                ? [color.withOpacity(0.3), color.withOpacity(0.1)]
                : [color.withOpacity(0.2), color.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isSelected ? const Color(0xFF1f2937) : Colors.white,
            size: 20,
          ),
        ),
          title: Text(
            title,
            style: TextStyle(
              color: isSelected ? const Color(0xFF1f2937) : Colors.white,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showTaskCreationOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Create New Task',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1f2937),
                ),
              ),
              const SizedBox(height: 24),
              _buildTaskOption(
                icon: Icons.edit_outlined,
                title: 'Manual Task',
                subtitle: 'Create a task manually',
                color: const Color(0xFF4facfe),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateTaskScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildTaskOption(
                icon: Icons.psychology_outlined,
                title: 'AI Assistant',
                subtitle: 'Let AI help create your task',
                color: const Color(0xFF00f2fe),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AITaskCreationScreen(),
                    ),
                  );
                  
                  if (result != null && result is Map<String, dynamic>) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateTaskScreen(
                          aiGeneratedData: result,
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildTaskOption(
                icon: Icons.mic_outlined,
                title: 'Voice Input',
                subtitle: 'Speak your task naturally',
                color: const Color(0xFF667eea),
                onTap: () async {
                  Navigator.pop(context);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VoiceTaskCreationScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1f2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Auth removed for demo release – always show app

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF667eea),
                Color(0xFF764ba2),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFFf093fb),
              Color(0xFFf5576c),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: _selectedIndex == 0
              ? TasksView(key: ValueKey(_currentFilter), filter: _currentFilter)
              : _selectedIndex == 1
              ? Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: const CalendarScreen(),
                )
              : Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: const SettingsScreen(),
                ),
        ),
      ),
      drawer: Drawer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF667eea),
                Color(0xFF764ba2),
              ],
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2c3e50),
                      Color(0xFF3498db),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(
                        Icons.task_alt,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'HelpME',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Your AI Task Assistant',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Task Filters Section
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'TASK FILTERS',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              _buildDrawerItem(
                icon: Icons.inbox_outlined,
                title: 'All Active',
                isSelected: _selectedIndex == 0 && _currentFilter == TaskFilter.all,
                onTap: () => _onFilterSelected(TaskFilter.all),
                color: const Color(0xFF4facfe),
              ),
              _buildDrawerItem(
                icon: Icons.task_alt_outlined,
                title: 'Active Tasks',
                isSelected: _selectedIndex == 0 && _currentFilter == TaskFilter.tasks,
                onTap: () => _onFilterSelected(TaskFilter.tasks),
                color: const Color(0xFF00f2fe),
              ),
              _buildDrawerItem(
                icon: Icons.alarm,
                title: 'Active Reminders',
                isSelected: _selectedIndex == 0 && _currentFilter == TaskFilter.reminders,
                onTap: () => _onFilterSelected(TaskFilter.reminders),
                color: const Color(0xFFffecd2),
              ),
              _buildDrawerItem(
                icon: Icons.check_circle_outline,
                title: 'Completed Tasks',
                isSelected: _selectedIndex == 0 && _currentFilter == TaskFilter.completed,
                onTap: () => _onFilterSelected(TaskFilter.completed),
                color: const Color(0xFF4facfe),
              ),
              _buildDrawerItem(
                icon: Icons.archive_outlined,
                title: 'Archived',
                isSelected: _selectedIndex == 0 && _currentFilter == TaskFilter.archived,
                onTap: () => _onFilterSelected(TaskFilter.archived),
                color: const Color(0xFFa8edea),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.white.withOpacity(0.3), Colors.transparent],
                  ),
                ),
              ),
              // Navigation Section
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  'NAVIGATION',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              _buildDrawerItem(
                icon: Icons.calendar_month,
                title: 'Calendar',
                isSelected: _selectedIndex == 1,
                onTap: () => _onDrawerItemTap(1),
                color: const Color(0xFFffecd2),
              ),
              _buildDrawerItem(
                icon: Icons.settings_outlined,
                title: 'Settings',
                isSelected: _selectedIndex == 2,
                onTap: () => _onDrawerItemTap(2),
                color: const Color(0xFFa8edea),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _selectedIndex == 0
          ? Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFf093fb),
                    Color(0xFFf5576c),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFf093fb).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () => _showTaskCreationOptions(context),
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 28,
                ),
              ),
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
            return Container(
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Loading your tasks...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            );
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return Container(
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Something went wrong',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error: $error',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final tasks = snapshot.data ?? [];
          if (tasks.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.task_alt,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No completed tasks yet',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete some tasks to see them here',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
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
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFffffff), Color(0xFFf8f9fa)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('EEEE, MMM d, yyyy').format(date),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ],
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
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Loading your tasks...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          );
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: $error',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final tasks = snapshot.data ?? [];
        if (tasks.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_task,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'No tasks here',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to create your first task',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
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
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFffffff), Color(0xFFf8f9fa)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.calendar_today,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('EEEE, MMM d, yyyy').format(date),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ],
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
        return const Color(0xFF4facfe);
      case 'social':
        return const Color(0xFF667eea);
      case 'personal':
        return const Color(0xFF00f2fe);
      case 'health':
        return const Color(0xFFf093fb);
      case 'work':
        return const Color(0xFFffecd2);
      case 'finance':
        return const Color(0xFFa8edea);
      default:
        return const Color(0xFF764ba2);
    }
  }

  LinearGradient _getCategoryGradient(String category) {
    switch (category.toLowerCase()) {
      case 'academics':
        return const LinearGradient(colors: [Color(0xFF4facfe), Color(0xFF00f2fe)]);
      case 'social':
        return const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]);
      case 'personal':
        return const LinearGradient(colors: [Color(0xFF00f2fe), Color(0xFF4facfe)]);
      case 'health':
        return const LinearGradient(colors: [Color(0xFFf093fb), Color(0xFFf5576c)]);
      case 'work':
        return const LinearGradient(colors: [Color(0xFFffecd2), Color(0xFFfcb69f)]);
      case 'finance':
        return const LinearGradient(colors: [Color(0xFFa8edea), Color(0xFFfed6e3)]);
      default:
        return const LinearGradient(colors: [Color(0xFF764ba2), Color(0xFF667eea)]);
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
    final categoryGradient = _getCategoryGradient(task.category);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _getCategoryColor(task.category).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
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
              width: 6.0,
              height: 80.0,
              decoration: BoxDecoration(
                gradient: categoryGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  bottomLeft: Radius.circular(16.0),
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
                padding: const EdgeInsets.all(6.0),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: task.isCompleted 
                        ? const LinearGradient(colors: [Color(0xFF4facfe), Color(0xFF00f2fe)])
                        : null,
                    border: Border.all(
                      color: task.isCompleted 
                          ? Colors.transparent 
                          : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: task.isCompleted
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 18,
                        )
                      : const SizedBox(
                          width: 22,
                          height: 22,
                        ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              decoration:
                                  task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                              color: task.isCompleted 
                                  ? Colors.grey.shade500 
                                  : const Color(0xFF2D3748),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: _getCategoryGradient(task.category),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            task.category.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (task.description != null && task.description!.isNotEmpty) ...[
                      Text(
                        task.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d, HH:mm').format(task.dueDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (task.isReminder && !isCompletedView && !isArchivedView)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3b82f6), Color(0xFF1d4ed8)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_active,
                        size: 16.0,
                        color: Colors.white,
                      ),
                    ),
                  if (isCompletedView || isArchivedView) 
                    _buildTaskActions(task, isCompletedView, isArchivedView),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
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
