import 'package:flutter/material.dart';
import 'package:aiassistant1/models/task.dart';
import 'package:aiassistant1/services/task_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:aiassistant1/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';

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
  final _quickInputController = TextEditingController();
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
  String _wordsSpoken = "";
  bool _isListening = false;
  bool _isProcessing = false;
  Map<String, dynamic>? _parsedResponse;

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
    setState(() {
      _isListening = true;
      _wordsSpoken = "";
    });
    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 5),
    );
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildListeningDialog(),
      );
    }
  }

  void _stopListening() async {
    setState(() {
      _isListening = false;
    });
    await _speechToText.stop();
    if (mounted) {
      Navigator.of(context).pop(); // Close the dialog
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (result.finalResult) {
      setState(() {
        _wordsSpoken = result.recognizedWords;
        _isListening = false;
        _isProcessing = true;
      });
      _getGeminiResponse(_wordsSpoken);
    } else {
      setState(() {
        _wordsSpoken = result.recognizedWords;
      });
    }
  }

  String getCurrentDateFormatted() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();
    return "$day-$month-$year";
  }

  Future<void> _getGeminiResponse(String userSpeech) async {
    const apiKey = 'Your_API_Key';
    const modelName = 'models/gemini-2.0-flash'; // or 'models/gemini-pro'

final url = Uri.parse(
  'https://generativelanguage.googleapis.com/v1/$modelName:generateContent?key=$apiKey',
);


    try {
      final today = getCurrentDateFormatted();

      final prompt = """
You are a smart task extraction bot that helps users create tasks from their voice input.
Today's date is: $today.

From the user's speech, extract the following information:
1. Task Title: A clear, concise title for the task
2. Due Date: Extract the date in DD-MM-YYYY format. If no specific date is mentioned:
   - If they say "today", use today's date
   - If they say "tomorrow", use tomorrow's date
   - If they say "next week", use 7 days from today
   - If no date is mentioned, use "unknown"
3. Due Time: Extract the time in HH:MM (24-hour) format. If no time is mentioned, use "00:00"
4. Category: Choose the most appropriate category from:
   - "academics" (for study, homework, research, etc.)
   - "social" (for meetings, events, gatherings, etc.)
   - "personal" (for personal tasks, hobbies, etc.)
   - "health" (for exercise, medical appointments, etc.)
   - "work" (for work-related tasks, projects, etc.)
   - "finance" (for bills, payments, budgeting, etc.)
   - "other" (if none of the above fit)

⚡ IMPORTANT RULES:
- The task title should be clear and specific
- The due date must be in DD-MM-YYYY format
- The due time must be in HH:MM format
- The category must be one of the exact values listed above
- If any information is unclear, make a reasonable assumption
- Respond ONLY in pure JSON format like this:
{
  "task": "Complete project report",
  "due_date": "28-09-2024",
  "due_time": "17:30",
  "category": "work"
}

User said: "$userSpeech"
""";

      final response = await http
          .post(
            url.replace(queryParameters: {'key': apiKey}),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "contents": [
                {
                  "parts": [
                    {"text": prompt},
                  ],
                },
              ],
              "generationConfig": {
                "temperature":
                    0.3, // Lower temperature for more consistent output
                "maxOutputTokens": 300,
              },
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final aiResponse =
            responseData['candidates']?[0]['content']['parts']?[0]['text']
                ?.trim() ??
            "{}";

        try {
         final cleanedResponse = aiResponse
    .replaceAll('```json', '')
    .replaceAll('```', '')
    .trim();

_parsedResponse = jsonDecode(cleanedResponse);

          if (_parsedResponse != null) {
            setState(() {
              // Update title with proper capitalization
              _titleController.text = _parsedResponse!['task']
                  .toString()
                  .split(' ')
                  .map(
                    (word) =>
                        word.isEmpty
                            ? ''
                            : word[0].toUpperCase() +
                                word.substring(1).toLowerCase(),
                  )
                  .join(' ');

              int hour = 0;
              int minute = 0;
              if (_parsedResponse!['due_time'] != null &&
                  _parsedResponse!['due_time'] != 'unknown') {
                final timeParts = _parsedResponse!['due_time'].split(':');
                if (timeParts.length == 2) {
                  hour = int.tryParse(timeParts[0]) ?? 0;
                  minute = int.tryParse(timeParts[1]) ?? 0;
                }
              }

              // Update due date if not unknown
              if (_parsedResponse!['due_date'] != 'unknown') {
                try {
                  final parts = _parsedResponse!['due_date'].split('-');
                  if (parts.length == 3) {
                    final day = int.parse(parts[0]);
                    final month = int.parse(parts[1]);
                    final year = int.parse(parts[2]);

                    // Validate date
                    if (day >= 1 &&
                        day <= 31 &&
                        month >= 1 &&
                        month <= 12 &&
                        year >= 2000 &&
                        year <= 2100) {
                      _dueDate = DateTime(year, month, day, hour, minute);
                    } else {
                      throw Exception('Invalid date values');
                    }
                  }
                } catch (e) {
                  // If date parsing fails, keep the current date
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not parse date, using current date'),
                    ),
                  );
                }
              }

              // Update category with proper validation
              String category = _parsedResponse!['category'].toLowerCase();
              if (!_categories.contains(category)) {
                category = 'other';
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Category not recognized, set to "other"'),
                  ),
                );
              }
              _selectedCategory = category;
              _updateAppBarColor();
            _saveTask();

            });
          }
        } catch (e) {
          _parsedResponse = {
            "task": "Failed to parse response",
            "due_date": "unknown",
            "category": "other",
          };
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error parsing response: ${e.toString()}')),
          );
        }

        setState(() {
          _isProcessing = false;
        });
        if (mounted) {
          Navigator.of(
            context,
          ).pop(); // Close dialog when processing is complete
        }
      } else {
        throw Exception(
          "Gemini API Error: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog on error
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
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
    _quickInputController.dispose();
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

  void _processQuickInput(String text) {
    if (text.isNotEmpty) {
      _getGeminiResponse(text);
      _quickInputController.clear();
    }
  }

  Widget _buildListeningDialog() {
    return AlertDialog(
      title: const Text('Listening...'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(_wordsSpoken),
          if (_isProcessing) const Text('Processing...'),
        ],
      ),
      actions: [
        TextButton(onPressed: _stopListening, child: const Text('Stop')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Create New Task' : 'Edit Task'),
        backgroundColor: _appBarColor,
        actions: [
          if (_speechEnabled && !_isListening && !_isProcessing)
            IconButton(icon: const Icon(Icons.mic), onPressed: _startListening),
          if (_isListening || _isProcessing)
            IconButton(icon: const Icon(Icons.stop), onPressed: _stopListening),
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
                      // Quick task input field
                      if (widget.task == null) // Only show for new tasks
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _quickInputController,
                              decoration: InputDecoration(
                                labelText: 'Quick Task Input',
                                hintText:
                                    'e.g., Add a task about visiting Japan next week',
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.send),
                                  onPressed:
                                      () => _processQuickInput(
                                        _quickInputController.text,
                                      ),
                                ),
                              ),
                              onFieldSubmitted:
                                  (value) => _processQuickInput(value),
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                          ],
                        ),
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
                    ],
                  ),
                ),
              ),
    );
  }
}
