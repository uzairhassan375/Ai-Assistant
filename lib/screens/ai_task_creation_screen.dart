import 'package:flutter/material.dart';
// Removed speech-to-text imports as they're no longer needed
// import 'package:speech_to_text/speech_recognition_result.dart';
// import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aiassistant1/models/task.dart';
import 'package:aiassistant1/services/task_services.dart';

class AITaskCreationScreen extends StatefulWidget {
  const AITaskCreationScreen({super.key});

  @override
  State<AITaskCreationScreen> createState() => _AITaskCreationScreenState();
}

class _AITaskCreationScreenState extends State<AITaskCreationScreen> {
  final _quickInputController = TextEditingController();
  // Removed speech-to-text functionality
  // final SpeechToText _speechToText = SpeechToText();
  // bool _speechEnabled = false;
  // String _wordsSpoken = "";
  // bool _isListening = false;
  bool _isProcessing = false;
  bool _isSaving = false;
  Map<String, dynamic>? _parsedResponse;
  String _originalUserInput = ""; // Store the original user input to determine task type

  final List<String> _categories = [
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
    // Removed speech initialization
    // initSpeech();
  }

  // Removed speech-related methods
  // void initSpeech() async {
  //   _speechEnabled = await _speechToText.initialize();
  //   setState(() {});
  // }

  @override
  void dispose() {
    _quickInputController.dispose();
    super.dispose();
  }

  // Removed all speech-related methods:
  // _startListening(), _stopListening(), _onSpeechResult()

  String getCurrentDateFormatted() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();
    return "$day-$month-$year";
  }

  Future<void> _getGeminiResponse(String userSpeech) async {
    print('🤖 Starting AI processing for: "$userSpeech"'); // Debug log
    
    // Store the original user input to determine task type later
    _originalUserInput = userSpeech;
    
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      print('❌ API key not found'); // Debug log
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: API key not found. Please check your .env file.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    const modelName = 'models/gemini-2.0-flash';

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
            url,
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
                "temperature": 0.3,
                "maxOutputTokens": 300,
              },
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        print('✅ Gemini API response received'); // Debug log
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final aiResponse =
            responseData['candidates']?[0]['content']['parts']?[0]['text']
                ?.trim() ??
            "{}";

        print('🔍 AI Response: $aiResponse'); // Debug log

        try {
          final cleanedResponse = aiResponse
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();

          print('🧹 Cleaned Response: $cleanedResponse'); // Debug log
          
          _parsedResponse = jsonDecode(cleanedResponse);
          print('📝 Parsed Response: $_parsedResponse'); // Debug log

          if (_parsedResponse != null) {
            setState(() {
              // Validate category
              String category = _parsedResponse!['category'].toLowerCase();
              if (!_categories.contains(category)) {
                category = 'other';
              }
              _parsedResponse!['category'] = category;
            });
          }
        } catch (e) {
          _parsedResponse = {
            "task": "Failed to parse response",
            "due_date": "unknown",
            "category": "other",
          };
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error parsing response: ${e.toString()}')),
            );
          }
        }

        setState(() {
          _isProcessing = false;
        });
        // Don't close the screen here - let user see the task preview and save button
        // if (mounted) {
        //   Navigator.of(context).pop(); // Close dialog when processing is complete
        // }
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
        // Don't close the screen on error - show error and let user try again
        // Navigator.of(context).pop(); // Close dialog on error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _processQuickInput(String text) {
    if (text.isNotEmpty) {
      setState(() {
        _isProcessing = true;
      });
      _getGeminiResponse(text);
      _quickInputController.clear();
    }
  }

  Future<void> _saveTask() async {
    print('💾 _saveTask called, _parsedResponse: $_parsedResponse'); // Debug log
    
    if (_parsedResponse == null) {
      print('❌ _parsedResponse is null, cannot save task'); // Debug log
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ User not authenticated'); // Debug log
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
      }
      return;
    }

    print('👤 User authenticated: ${user.uid}'); // Debug log

    try {
      // Parse date and time
      DateTime dueDate = DateTime.now().add(const Duration(days: 1));
      
      if (_parsedResponse!['due_date'] != 'unknown') {
        try {
          final parts = _parsedResponse!['due_date'].split('-');
          if (parts.length == 3) {
            final day = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final year = int.parse(parts[2]);

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

            // Validate date
            if (day >= 1 && day <= 31 && month >= 1 && month <= 12 && year >= 2000 && year <= 2100) {
              dueDate = DateTime(year, month, day, hour, minute);
            }
          }
        } catch (e) {
          // Use default date if parsing fails
        }
      }

      final taskService = TaskService();
      
      // Determine if this is a reminder based on the original user input
      final isReminderTask = _originalUserInput.toLowerCase().contains('remind') || 
                            _originalUserInput.toLowerCase().contains('reminder');
      
      final task = Task(
        title: _parsedResponse!['task'].toString(), // AI response uses 'task', but Task model uses 'title'
        description: null, // Add description field
        dueDate: dueDate,
        userId: user.uid,
        category: _parsedResponse!['category'],
        priority: TaskPriority.medium,
        isReminder: isReminderTask, // Set based on user input
        isCompleted: false, // Add isCompleted field
        isArchived: false, // Add isArchived field
        subtasks: [], // Add subtasks field
      );

      print('🚀 About to create task: ${task.title}'); // Debug log
      print('   Original input: "$_originalUserInput"'); // Debug log
      print('   Task details: title="${task.title}", category="${task.category}", dueDate=${task.dueDate}'); // Debug log
      print('   Task flags: isArchived=${task.isArchived}, isCompleted=${task.isCompleted}, isReminder=${task.isReminder}'); // Debug log

      final createdTask = await taskService.createTask(task);
      print('✅ AI Task created successfully: ${createdTask.title} with ID: ${createdTask.id}'); // Debug log
      print('   Task details: isArchived=${createdTask.isArchived}, isCompleted=${createdTask.isCompleted}, isReminder=${createdTask.isReminder}'); // Debug log

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task created successfully!')),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      print('❌ Error saving task: $e'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save task: $e')),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // Removed _buildListeningDialog() method since speech functionality is removed

  Widget _buildTaskPreview() {
    if (_parsedResponse == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.task_alt, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Task Preview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPreviewItem('Title', _parsedResponse!['task'] ?? 'Unknown'),
            _buildPreviewItem('Due Date', _parsedResponse!['due_date'] ?? 'Unknown'),
            _buildPreviewItem('Time', _parsedResponse!['due_time'] ?? '00:00'),
            _buildPreviewItem('Category', _parsedResponse!['category'] ?? 'other'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveTask,
                    icon: _isSaving 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Saving...' : 'Save Task'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _parsedResponse = null;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Task Creator'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        // Removed microphone icon from AppBar
        // actions: [
        //   if (_speechEnabled && !_isListening && !_isProcessing)
        //     IconButton(
        //       icon: const Icon(Icons.mic),
        //       onPressed: _startListening,
        //     ),
        //   if (_isListening || _isProcessing)
        //     IconButton(
        //       icon: const Icon(Icons.stop),
        //       onPressed: _stopListening,
        //     ),
        // ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Tell me what task you want to create',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _quickInputController,
                    decoration: InputDecoration(
                      labelText: 'Describe your task',
                      hintText: 'e.g., Remind me to buy groceries tomorrow at 5 PM',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () => _processQuickInput(_quickInputController.text),
                      ),
                    ),
                    maxLines: 3,
                    onFieldSubmitted: (value) => _processQuickInput(value),
                  ),
                  const SizedBox(height: 16),
                  if (_isProcessing)
                    const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text('AI is processing your request...'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            _buildTaskPreview(),
            if (_parsedResponse == null && !_isProcessing)
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.psychology,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Type your task or use voice input',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'I can understand dates, times, and categories',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
