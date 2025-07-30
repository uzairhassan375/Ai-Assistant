import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aiassistant1/models/task.dart';
import 'package:aiassistant1/services/task_services.dart';

class VoiceTaskCreationScreen extends StatefulWidget {
  const VoiceTaskCreationScreen({super.key});

  @override
  State<VoiceTaskCreationScreen> createState() => _VoiceTaskCreationScreenState();
}

class _VoiceTaskCreationScreenState extends State<VoiceTaskCreationScreen>
    with TickerProviderStateMixin {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _wordsSpoken = "";
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isSaving = false;
  bool _hasError = false;
  String _errorMessage = "";
  Map<String, dynamic>? _parsedResponse;
  String _originalUserInput = "";
  
  // Animation controllers
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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
    
    // Initialize pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    initSpeech();
  }

  void initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    if (_speechEnabled) {
      // Automatically start listening when screen opens
      _startListening();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _speechToText.stop();
    _pulseController.dispose();
    super.dispose();
  }

  void _startListening() async {
    setState(() {
      _isListening = true;
      _wordsSpoken = "";
      _parsedResponse = null;
      _hasError = false;
      _errorMessage = "";
    });
    
    // Start pulse animation
    _pulseController.repeat(reverse: true);
    
    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
    );
  }

  void _stopListening() async {
    // Stop pulse animation
    _pulseController.stop();
    await _speechToText.stop();
    
    // If we have spoken words, process them immediately
    if (_wordsSpoken.isNotEmpty) {
      setState(() {
        _isListening = false;
        _isProcessing = true;
      });
      _originalUserInput = _wordsSpoken;
      _getGeminiResponse(_wordsSpoken);
    } else {
      // If no words spoken, go back to ready state
      setState(() {
        _isListening = false;
      });
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _wordsSpoken = result.recognizedWords;
    });

    if (result.finalResult) {
      // Stop pulse animation and start processing
      _pulseController.stop();
      setState(() {
        _isListening = false;
        _isProcessing = true;
      });
      _originalUserInput = _wordsSpoken;
      _getGeminiResponse(_wordsSpoken);
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
    print('🤖 Starting AI processing for voice input: "$userSpeech"');
    
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      print('❌ API key not found');
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

    try {
      // Try different models in order of preference
      final models = [
        'gemini-1.5-flash-latest',
        'gemini-1.5-flash',
        'gemini-pro',
        'gemini-1.5-pro-latest'
      ];
      
      Exception? lastError;
      
      for (String model in models) {
        try {
          final url = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
          );
          
          final success = await _tryGeminiRequest(url, userSpeech);
          if (success) return; // Exit if successful
          
        } catch (e) {
          lastError = e is Exception ? e : Exception(e.toString());
          print('❌ Model $model failed: $e');
          continue; // Try next model
        }
      }
      
      // If all models failed, throw the last error
      throw lastError ?? Exception('All Gemini models are currently unavailable');
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _hasError = true;
        _errorMessage = e.toString().contains('503') || e.toString().contains('overloaded')
            ? 'Gemini AI is currently overloaded. Please try again in a few moments.'
            : 'Error: ${e.toString()}';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage)),
        );
      }
    }
  }

  Future<bool> _tryGeminiRequest(Uri url, String userSpeech) async {
    String prompt = """
You are a smart task assistant. Parse the user's voice input and extract task information.

Current date: ${getCurrentDateFormatted()}

Return a JSON response with these exact keys:
- "task": The main task title (clean and concise)
- "due_date": Date in DD-MM-YYYY format (if mentioned, otherwise use tomorrow's date)
- "due_time": Time in HH:MM format (if mentioned, otherwise "unknown")
- "category": One of: academics, social, personal, health, work, finance, other

Categories:
- "academics" (for study, homework, research, etc.)
- "social" (for events, meetings, social activities)
- "personal" (for personal tasks, shopping, etc.)
- "health" (for medical, fitness, wellness)
- "work" (for professional tasks, deadlines)
- "finance" (for money, bills, investments)
- "other" (for anything else)

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
        .timeout(const Duration(seconds: 45)); // Reduced timeout

    if (response.statusCode == 200) {
      print('✅ Gemini API response received');
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final aiResponse =
          responseData['candidates']?[0]['content']['parts']?[0]['text']
              ?.trim() ??
          "{}";

      print('🔍 AI Response: $aiResponse');

      try {
        final cleanedResponse = aiResponse
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        print('🧹 Cleaned Response: $cleanedResponse');
        
        _parsedResponse = jsonDecode(cleanedResponse);
        print('📝 Parsed Response: $_parsedResponse');

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
      return true; // Success
    } else if (response.statusCode == 503) {
      throw Exception("Service temporarily unavailable (503)");
    } else {
      throw Exception(
        "API Error: ${response.statusCode} - ${response.body}",
      );
    }
  }

  void _tryAgain() {
    setState(() {
      _wordsSpoken = "";
      _parsedResponse = null;
      _isProcessing = false;
      _hasError = false;
      _errorMessage = "";
    });
    _startListening();
  }

  Future<void> _saveTask() async {
    print('💾 Voice _saveTask called, _parsedResponse: $_parsedResponse');
    
    if (_parsedResponse == null) {
      print('❌ _parsedResponse is null, cannot save task');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ User not authenticated');
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

    print('👤 User authenticated: ${user.uid}');

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
        title: _parsedResponse!['task'].toString(),
        description: null,
        dueDate: dueDate,
        userId: user.uid,
        category: _parsedResponse!['category'],
        priority: TaskPriority.medium,
        isReminder: isReminderTask,
        isCompleted: false,
        isArchived: false,
        subtasks: [],
      );

      print('🚀 About to create voice task: ${task.title}');
      print('   Original voice input: "$_originalUserInput"');
      print('   Task details: title="${task.title}", category="${task.category}", dueDate=${task.dueDate}');
      print('   Task flags: isArchived=${task.isArchived}, isCompleted=${task.isCompleted}, isReminder=${task.isReminder}');

      final createdTask = await taskService.createTask(task);
      print('✅ Voice Task created successfully: ${createdTask.title} with ID: ${createdTask.id}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task created successfully!')),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      print('❌ Error saving voice task: $e');
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPreviewRow('Title', _parsedResponse!['task'] ?? ''),
            _buildPreviewRow('Due Date', _parsedResponse!['due_date'] ?? ''),
            _buildPreviewRow('Due Time', _parsedResponse!['due_time'] ?? 'Not specified'),
            _buildPreviewRow('Category', _parsedResponse!['category'] ?? ''),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _tryAgain,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
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
                    backgroundColor: Colors.deepPurple,
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

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
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
        title: const Text('Voice Task Creator'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Listening state
                if (_isListening) ...[
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red.withOpacity(0.2),
                          ),
                          child: const Icon(
                            Icons.mic,
                            size: 60,
                            color: Colors.red,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Listening...',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Try saying something',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 25),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _wordsSpoken.isEmpty ? 'Speak now...' : _wordsSpoken,
                      style: TextStyle(
                        fontSize: 16,
                        color: _wordsSpoken.isEmpty ? Colors.grey[500] : Colors.black87,
                        fontStyle: _wordsSpoken.isEmpty ? FontStyle.italic : FontStyle.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton.icon(
                    onPressed: _stopListening,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop Listening'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ]
                
                // Processing state
                else if (_isProcessing) ...[
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.deepPurple.withOpacity(0.1),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Processing your request...',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'You said: "$_wordsSpoken"',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ]
                
                // Task preview state
                else if (_parsedResponse != null) ...[
                  const Icon(
                    Icons.check_circle,
                    size: 80,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Task Ready!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  _buildTaskPreview(),
                ]
                
                // Error state
                else if (_hasError) ...[
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withOpacity(0.1),
                    ),
                    child: const Icon(
                      Icons.error,
                      size: 50,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'Something went wrong',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton.icon(
                    onPressed: _tryAgain,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ]
                
                // Initial state
                else ...[
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.deepPurple.withOpacity(0.1),
                      border: Border.all(
                        color: Colors.deepPurple.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.mic,
                      size: 60,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Ready to listen',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Tap the microphone to start voice input',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: _speechEnabled ? _startListening : null,
                    icon: const Icon(Icons.mic),
                    label: const Text('Start Voice Input'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
