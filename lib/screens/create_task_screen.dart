import 'package:aiassistant1/screens/subtask_screen.dart';
import 'package:aiassistant1/screens/ai_task_creation_screen.dart';
import 'package:aiassistant1/screens/voice_task_creation_screen.dart';
import 'package:flutter/material.dart';
import 'package:aiassistant1/models/task.dart';
import 'package:aiassistant1/services/task_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:intl/intl.dart';
import 'package:aiassistant1/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:aiassistant1/models/subtask.dart';

class CreateTaskScreen extends StatefulWidget {
  final Task? task;
  final DateTime? initialDate;
  const CreateTaskScreen({super.key, this.task, this.initialDate});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<Subtask> _subtasks = [];
  late DateTime _dueDate;
  bool _isLoading = false;
  String _selectedCategory = 'other';
  TaskPriority _selectedPriority = TaskPriority.medium;
  bool _isReminder = false;
  Color _appBarColor = Colors.blue;

  final List<String> _categories = [
    'academics',
    'social',
    'personal',
    'health',
    'work',
    'finance',
    'other',
  ];

  // Voice recognition variables
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description ?? '';
      _dueDate = widget.task!.dueDate;
      _selectedCategory = widget.task!.category;
      _selectedPriority = widget.task!.priority;
      _isReminder = widget.task!.isReminder;
      _subtasks = List.from(widget.task!.subtasks); // Initialize with existing subtasks
      _updateAppBarColor();
    } else {
      _dueDate =
          widget.initialDate ?? DateTime.now().add(const Duration(days: 1));
      // Initialize time to midnight for new tasks if no initialDate is provided with time
      _dueDate = DateTime(_dueDate.year, _dueDate.month, _dueDate.day, 0, 0);
      _updateAppBarColor();
    }
    initSpeech();
  }

  void initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    // Navigate to the new voice task creation screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VoiceTaskCreationScreen(),
      ),
    );
    
    // If a task was created successfully, go back to home screen
    if (result == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _updateAppBarColor() {
    Color color;
    switch (_selectedCategory.toLowerCase()) {
      case 'academics':
        color = Colors.blue;
        break;
      case 'social':
        color = Colors.purple;
        break;
      case 'personal':
        color = Colors.green;
        break;
      case 'health':
        color = Colors.red;
        break;
      case 'work':
        color = Colors.orange;
        break;
      case 'finance':
        color = Colors.teal;
        break;
      default:
        // Use priority color if category is 'other'
        switch (_selectedPriority) {
          case TaskPriority.low:
            color = Colors.green;
            break;
          case TaskPriority.medium:
            color = Colors.orange;
            break;
          case TaskPriority.high:
            color = Colors.red;
            break;
          case TaskPriority.urgent:
            color = Colors.purple;
            break;
        }
        break;
    }
    setState(() {
      _appBarColor = color;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      // If a date is picked, show the time picker
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dueDate),
      );

      if (pickedTime != null) {
        setState(() {
          _dueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      } else {
        // If only date is picked, keep the existing time or set to midnight
        setState(() {
          _dueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            _dueDate.hour,
            _dueDate.minute,
          );
        });
      }
    } else {
      // If no date is picked, do nothing
    }
  }

  void _saveTask() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final taskService = TaskService();
      final task = Task(
        id: widget.task?.id,
        title: _titleController.text,
        description:
            _descriptionController.text.isEmpty
                ? null
                : _descriptionController.text,
        dueDate: _dueDate,
        isCompleted: widget.task?.isCompleted ?? false,
        userId: user.uid,
        category: _selectedCategory,
        subtasks: _subtasks,
        priority: _selectedPriority,
        isArchived: widget.task?.isArchived ?? false,
        isReminder: _isReminder,
      );

      try {
        String? taskId = widget.task?.id;
        if (_isReminder) {
          var status = await Permission.scheduleExactAlarm.status;
          if (status.isDenied) {
            final result = await Permission.scheduleExactAlarm.request();
            if (result.isDenied || result.isPermanentlyDenied) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Permission denied. Reminder cannot be set.'),
                  ),
                );
              }
              setState(() {
                _isLoading = false;
              });
              return;
            }
          }
        }
        if (widget.task == null) {
          // Create new task
          final createdTask = await taskService.createTask(task);
          taskId = createdTask.id;
          if (_isReminder && taskId != null) {
            await NotificationService().scheduleReminderNotification(
              id: taskId.hashCode,
              title: 'Task Reminder',
              body: task.title,
              dueDate: task.dueDate,
            );
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Task created successfully!')),
            );
          }
        } else {
          // Update existing task
          await taskService.updateTask(task);
          if (taskId != null) {
            if (_isReminder) {
              await NotificationService().scheduleReminderNotification(
                id: taskId.hashCode,
                title: 'Task Reminder',
                body: task.title,
                dueDate: task.dueDate,
              );
            } else {
              await NotificationService().cancelNotification(taskId.hashCode);
            }
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Task updated successfully!')),
            );
          }
        }
        if (context.mounted) {
          Navigator.pop(context); // Go back after saving
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to save task: $e')));
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Create New Task' : 'Edit Task'),
        backgroundColor: _appBarColor,
        actions: [
          if (widget.task == null) // Only show AI icon when creating new task
            IconButton(
              icon: const Icon(Icons.message),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AITaskCreationScreen(),
                  ),
                );
                if (result == true && mounted) {
                  Navigator.pop(context, true); // Close this screen and refresh home
                }
              },
              tooltip: 'AI Task Creator',
            ),
          if (_speechEnabled)
            IconButton(icon: const Icon(Icons.mic), onPressed: _startListening),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveTask,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: <Widget>[
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                        ),
                        maxLines: 3,
                      ),
                      ListTile(
                        title: Text(
                          'Due Date: ${DateFormat('MMM dd, yyyy HH:mm').format(_dueDate)}', // Updated format to include time
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () => _selectDate(context),
                      ),
                      SwitchListTile(
                        title: const Text('Set as Reminder'),
                        value: _isReminder,
                        onChanged: (value) {
                          setState(() {
                            _isReminder = value;
                          });
                        },
                      ),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        value: _selectedCategory,
                        items:
                            _categories.map((String category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(
                                  category[0].toUpperCase() +
                                      category.substring(1),
                                ),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedCategory = newValue;
                              _updateAppBarColor();
                            });
                          }
                        },
                      ),
                      DropdownButtonFormField<TaskPriority>(
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                        ),
                        value: _selectedPriority,
                        items:
                            TaskPriority.values.map((TaskPriority priority) {
                              return DropdownMenuItem<TaskPriority>(
                                value: priority,
                                child: Text(
                                  priority
                                      .toString()
                                      .split('.')
                                      .last
                                      .toUpperCase(),
                                ),
                              );
                            }).toList(),
                        onChanged: (TaskPriority? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedPriority = newValue;
                              _updateAppBarColor();
                            });
                          }
                        },
                      ),

if (widget.task != null &&
    widget.task!.subtasks.isNotEmpty) ...[
  const SizedBox(height: 20),
  const Text(
    'Subtasks',
    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
  ),
  const SizedBox(height: 8),
  ...widget.task!.subtasks.map((subtask) => Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: const Icon(Icons.subdirectory_arrow_right),
          title: Text(subtask.title),
          subtitle: Text(
            '${subtask.description}\nDue: ${DateFormat('MMM dd, yyyy – HH:mm').format(subtask.deadline)}',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      )),
],


                      const SizedBox(height: 16),
                      if (widget.task == null) // Only show when creating new task
                        ElevatedButton.icon(
  icon: const Icon(Icons.playlist_add),
  label: const Text('Add Subtasks'),
  onPressed: () async {
    bool isEditMode = widget.task != null;
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => SubtaskScreen(
        existingSubtasks: _subtasks,
        isEditMode: isEditMode,
      ),
    ),
  );

  if (result != null && result is List<Subtask>) {
    setState(() {
      _subtasks = result;
    });
  }
},

),

                    ],
                  ),
                ),
              ),
    );
  }
}
