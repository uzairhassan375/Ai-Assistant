import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:aiassistant1/models/task.dart';
import 'package:aiassistant1/services/task_services.dart';
import 'package:aiassistant1/screens/create_task_screen.dart';
import 'package:aiassistant1/screens/task_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Task>> _events = {};
  final TaskService _taskService = TaskService();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Get tasks for the current month
    final startDate = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final endDate = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

    // Get ALL tasks (active, completed, and archived) for comprehensive calendar view
    final tasks = await _taskService
        .getTasksByDateRange(
          user.uid, 
          startDate, 
          endDate,
          filter: TaskViewFilter.all, // Explicitly get all tasks
        )
        .first;

    final Map<DateTime, List<Task>> newEvents = {};
    for (var task in tasks) {
      final date = DateTime(
        task.dueDate.year,
        task.dueDate.month,
        task.dueDate.day,
      );
      if (newEvents[date] == null) {
        newEvents[date] = [];
      }
      newEvents[date]!.add(task);
    }

    setState(() {
      _events = newEvents;
    });
  }

  List<Task> _getTasksForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  Future<void> _createTask(DateTime date) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTaskScreen(initialDate: date),
      ),
    );
    if (result == true) {
      _loadEvents();
    }
  }

  Future<void> _navigateToTaskDetail(Task task) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(task: task),
      ),
    );
    
    // Refresh events if task was modified/deleted
    if (result == true) {
      _loadEvents();
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'academics':
        return Colors.blue;
      case 'social':
        return Colors.green;
      case 'personal':
        return Colors.purple;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Calendar
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              _loadEvents();
            },
            eventLoader: _getTasksForDay,
            calendarStyle: const CalendarStyle(
              markersMaxCount: 3,
              markerDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Task List for Selected Day
          Expanded(
            child: _selectedDay == null
                ? const Center(child: Text('No day selected'))
                : _buildTaskList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createTask(_selectedDay ?? DateTime.now()),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskList() {
    final tasks = _getTasksForDay(_selectedDay!);
    
    if (tasks.isEmpty) {
      return const Center(
        child: Text('No tasks for this day'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _getCategoryColor(task.category).withOpacity(0.2),
                border: Border.all(
                  color: _getCategoryColor(task.category),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: task.isCompleted
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.green,
                    )
                  : null,
            ),
            title: Text(
              task.title,
              style: TextStyle(
                decoration: task.isCompleted 
                    ? TextDecoration.lineThrough 
                    : null,
                color: task.isCompleted 
                    ? Colors.grey 
                    : null,
              ),
            ),
            subtitle: (task.description?.isNotEmpty ?? false)
                ? Text(
                    task.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(task.category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getCategoryColor(task.category).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    task.category.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getCategoryColor(task.category),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('HH:mm').format(task.dueDate),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            onTap: () => _navigateToTaskDetail(task),
          ),
        );
      },
    );
  }
}
