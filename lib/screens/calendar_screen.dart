import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:aiassistant1/models/task.dart';
import 'package:aiassistant1/services/task_services.dart';
import 'package:aiassistant1/screens/create_task_screen.dart';
// import 'package:firebase_auth/firebase_auth.dart';
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
  String? _selectedCategory;
  bool _showCompletedTasks = true;
  final List<String> _categories = [
    'all',
    'academics',
    'social',
    'personal',
    'health',
    'work',
    'finance',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    const String demoUserId = 'demo_user';

    // Get tasks for the current month
    final startDate = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final endDate = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

    final tasks =
        await _taskService
            .getTasksByDateRange(demoUserId, startDate, endDate)
            .first;

    final Map<DateTime, List<Task>> newEvents = {};
    for (var task in tasks) {
      if (!_showCompletedTasks && task.isCompleted) continue;
      if (_selectedCategory != null &&
          _selectedCategory != 'all' &&
          task.category != _selectedCategory) {
        continue;
      }

      final date = DateTime(
        task.dueDate.year,
        task.dueDate.month,
        task.dueDate.day,
      );
      if (newEvents[date] == null) newEvents[date] = [];
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

  Future<void> _rescheduleTask(Task task, DateTime newDate) async {
    try {
      final updatedTask = task.copyWith(
        dueDate: DateTime(
          newDate.year,
          newDate.month,
          newDate.day,
          task.dueDate.hour,
          task.dueDate.minute,
        ),
      );
      await _taskService.updateTask(updatedTask);
      _loadEvents();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Task rescheduled to ${DateFormat('MMM d, y').format(newDate)}',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error rescheduling task: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Category Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children:
                  _categories.map((category) {
                    final isSelected = category == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          category[0].toUpperCase() + category.substring(1),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = selected ? category : null;
                            _loadEvents();
                          });
                        },
                        backgroundColor: Colors.grey[200],
                        selectedColor: _getCategoryColor(
                          category,
                        ).withOpacity(0.2),
                        checkmarkColor: _getCategoryColor(category),
                        labelStyle: TextStyle(
                          color:
                              isSelected
                                  ? _getCategoryColor(category)
                                  : Colors.black,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
          // Calendar
          DragTarget<Task>(
            onWillAcceptWithDetails: (details) => details.data != null,
            onAcceptWithDetails: (details) {
              if (_selectedDay != null) {
                _rescheduleTask(details.data, _selectedDay!);
              }
            },
            builder: (context, candidateData, rejectedData) {
              return TableCalendar(
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
                calendarStyle: CalendarStyle(
                  markersMaxCount: 3,
                  markerDecoration: BoxDecoration(
                    color:
                        candidateData.isNotEmpty ? Colors.green : Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          // Task List
          Expanded(
            child:
                _selectedDay == null
                    ? const Center(child: Text('No day selected'))
                    : _calendarFormat == CalendarFormat.week
                    ? _buildWeekView()
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

  Widget _buildWeekView() {
    final weekStart = _focusedDay.subtract(
      Duration(days: _focusedDay.weekday - 1),
    );
    final weekDays = List.generate(
      7,
      (index) => weekStart.add(Duration(days: index)),
    );

    return Row(
      children:
          weekDays.map((day) {
            final tasks = _getTasksForDay(day);
            return Expanded(
              child: DragTarget<Task>(
                onWillAcceptWithDetails: (details) => details.data != null,
                onAcceptWithDetails: (details) {
                  _rescheduleTask(details.data, day);
                },
                builder: (context, candidateData, rejectedData) {
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[300]!),
                          ),
                          color:
                              candidateData.isNotEmpty
                                  ? Colors.green.withOpacity(0.1)
                                  : null,
                        ),
                        child: Column(
                          children: [
                            Text(
                              DateFormat('E').format(day),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat('d').format(day),
                              style: TextStyle(
                                color:
                                    isSameDay(day, DateTime.now())
                                        ? Theme.of(context).primaryColor
                                        : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: DragTarget<Task>(
                          onWillAcceptWithDetails:
                              (details) => details.data != null,
                          onAcceptWithDetails: (details) {
                            _rescheduleTask(details.data, day);
                          },
                          builder: (context, candidateData, rejectedData) {
                            return Container(
                              color:
                                  candidateData.isNotEmpty
                                      ? Colors.green.withOpacity(0.1)
                                      : null,
                              child: ListView.builder(
                                itemCount: tasks.length,
                                itemBuilder: (context, index) {
                                  final task = tasks[index];
                                  return Draggable<Task>(
                                    data: task,
                                    feedback: Material(
                                      elevation: 4,
                                      child: Container(
                                        width: 100,
                                        padding: const EdgeInsets.all(8),
                                        color: _getCategoryColor(
                                          task.category,
                                        ).withOpacity(0.2),
                                        child: Text(
                                          task.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    child: Card(
                                      margin: const EdgeInsets.all(4),
                                      child: ListTile(
                                        title: Text(
                                          task.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            decoration:
                                                task.isCompleted
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                          ),
                                        ),
                                        subtitle: Text(
                                          DateFormat(
                                            'HH:mm',
                                          ).format(task.dueDate),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          }).toList(),
    );
  }

  Widget _buildTaskList() {
    final tasks = _getTasksForDay(_selectedDay!);

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No tasks for ${DateFormat('MMMM d, y').format(_selectedDay!)}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Draggable<Task>(
          data: task,
          feedback: Material(
            elevation: 4,
            child: Container(
              width: 200,
              padding: const EdgeInsets.all(8),
              color: _getCategoryColor(task.category).withOpacity(0.2),
              child: Text(
                task.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(
                task.title,
                style: TextStyle(
                  decoration:
                      task.isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Text(
                task.description ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
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
                        color: _getCategoryColor(
                          task.category,
                        ).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      task.category[0].toUpperCase() +
                          task.category.substring(1),
                      style: TextStyle(
                        color: _getCategoryColor(task.category),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Checkbox(
                    value: task.isCompleted,
                    onChanged: (value) async {
                      try {
                        await _taskService.toggleTaskCompletion(
                          task.id!,
                          value!,
                        );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error updating task: $e')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
}
