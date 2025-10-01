import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/connectivity_service.dart';
import '../utils/ai_config.dart';
import 'package:api_key_pool/api_key_pool.dart';
import '../services/task_services.dart';
import '../models/task.dart';

//Implementing Voice Ai
class CreateVoiceTaskScreen extends StatefulWidget {
  const CreateVoiceTaskScreen({super.key});

  @override
  State<CreateVoiceTaskScreen> createState() => _HomePageState();
}

class _HomePageState extends State<CreateVoiceTaskScreen> {
  final SpeechToText _speechToText = SpeechToText();
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _speechEnabled = false;
  String _wordsSpoken = "";
  String _aiResponse = "";
  bool _isProcessing = false;
  bool _isListening = false;
  bool _isCheckingConnection = false;
  Map<String, dynamic>? _parsedResponse;

  @override
  void initState() {
    super.initState();
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
      _aiResponse = "";
    });
    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
    );
  }

  void _stopListening() async {
    setState(() {
      _isListening = false;
    });
    await _speechToText.stop();
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (result.finalResult) {
      setState(() {
        _wordsSpoken = result.recognizedWords;
      });
      // Process the voice command after getting final result
      _processVoiceCommand(_wordsSpoken);
    } else {
      setState(() {
        _wordsSpoken = result.recognizedWords;
      });
    }
  }

  Future<void> _processVoiceCommand(String userSpeech) async {
    if (userSpeech.trim().isEmpty) return;

    setState(() {
      _isCheckingConnection = true;
    });

    // Check internet connection BEFORE making API call
    final hasConnection = await _connectivityService.validateConnectionForAI(
      context,
      feature: "Voice AI Task Creation",
    );

    setState(() {
      _isCheckingConnection = false;
    });

    if (!hasConnection) {
      // No internet connection, don't proceed with API call
      setState(() {
        _isProcessing = false;
        _aiResponse = "Internet connection required for AI processing";
      });
      return;
    }

    // Proceed with Gemini API call if connection is available
    await _getGeminiResponse(userSpeech);
  }

  String getCurrentDateFormatted() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();
    return "$day-$month-$year";
  }

  Future<void> _saveTask() async {
    if (_parsedResponse == null) return;

    try {
      // Parse the due date
      DateTime dueDate = DateTime.now().add(const Duration(days: 1));
      if (_parsedResponse!['due_date'] != 'unknown') {
        try {
          final parts = _parsedResponse!['due_date'].split('-');
          if (parts.length == 3) {
            final day = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final year = int.parse(parts[2]);
            dueDate = DateTime(year, month, day);
          }
        } catch (e) {
          // Use default date if parsing fails
        }
      }

      // Parse priority
      TaskPriority priority = TaskPriority.medium;
      if (_parsedResponse!['priority'] != null) {
        try {
          priority = TaskPriority.values.firstWhere(
            (e) => e.toString().split('.').last == _parsedResponse!['priority'],
            orElse: () => TaskPriority.medium,
          );
        } catch (e) {
          priority = TaskPriority.medium;
        }
      }

      // Create task object
      final task = Task(
        title: _parsedResponse!['task'],
        description: null,
        dueDate: dueDate,
        userId: 'local_user', // Since we're using local storage, use a fixed user ID
        category: _parsedResponse!['category'] ?? 'other',
        priority: priority,
        isCompleted: false,
        isArchived: false,
        isReminder: false,
        subtasks: [],
      );

      // Save task using TaskService
      final taskService = TaskService();
      await taskService.createTask(task);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task "${_parsedResponse!['task']}" saved!'),
          duration: const Duration(seconds: 2),
        ),
      );

      setState(() {
        _wordsSpoken = "";
        _aiResponse = "";
        _parsedResponse = null;
      });
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save task: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _getGeminiResponse(String userSpeech) async {
    // Check internet connection BEFORE making API call
    setState(() {
      _isCheckingConnection = true;
    });

    final hasConnection = await _connectivityService.validateConnectionForAI(
      context,
      feature: "Voice AI Task Creation",
    );

    setState(() {
      _isCheckingConnection = false;
    });

    if (!hasConnection) {
      setState(() {
        _isProcessing = false;
        _aiResponse = "Internet connection required for AI processing";
      });
      return;
    }

    final apiKey = ApiKeyPool.getKey();
    if (apiKey.isEmpty) {
      setState(() {
        _isProcessing = false;
        _aiResponse = "API key not found. Please check your API key pool configuration.";
      });
      return;
    }
    
    final modelName = 'models/${AIConfig.modelName}';

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1/$modelName:generateContent?key=$apiKey',
    );

    try {
      setState(() {
        _isProcessing = true;
      });

      final today = getCurrentDateFormatted();

      final prompt = """
You are a smart task extraction bot.
Today's date is: $today.

From the user's speech, extract:
- task: (description of the task)
- due_date: (in DD-MM-YYYY format)
- category: (choose smartly from the following categories. If unsure, select "other" and specify a custom name)
    - "playing activity"
    - "study activity"
    - "household activity"
    - "other"

⚡ IMPORTANT RULES:
- You must ALWAYS return all three fields: task, due_date, and category.
- If the due_date is missing, set it as "unknown". Do not ask the user for anything.
- Respond ONLY in pure JSON format like this:
{
  "task": "buy milk",
  "due_date": "28-09-2025",
  "category": "household activity"
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
                "temperature": 0.5,
                "maxOutputTokens": 300,
                "responseMimeType": "application/json",
              },
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Gemini returns the text in a different structure than Ollama
        final aiResponse =
            responseData['candidates']?[0]['content']['parts']?[0]['text']
                ?.trim() ??
            "{}";

        try {
          _parsedResponse = jsonDecode(aiResponse);
        } catch (e) {
          _parsedResponse = {
            "task": "Failed to parse response",
            "due_date": "unknown",
            "category": "error",
          };
        }

        setState(() {
          _aiResponse = aiResponse;
          _isProcessing = false;
        });
      } else {
        throw Exception(
          "Gemini API Error: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      // Handle network errors specifically
      if (_connectivityService.isNetworkError(e)) {
        _connectivityService.handleNetworkError(context, e);
        setState(() {
          _aiResponse = "Connection failed. Please check your internet connection.";
          _isProcessing = false;
        });
      } else {
        setState(() {
          _aiResponse = "Error: ${e.toString()}";
          _isProcessing = false;
        });
      }
    }
  }

  //   Future<void> _getOllamaResponse(String userSpeech) async {
  //     try {
  //       final url = Uri.parse('http://127.0.0.1:11434/api/generate');
  //       final today = getCurrentDateFormatted();

  //       final fullPrompt = """
  // You are a smart task extraction bot.
  // Today's date is: $today.

  // From the user's speech, extract:
  // - task: (description of the task)
  // - due_date: (in DD-MM-YYYY format)
  // - category: (choose smartly from the following categories. If unsure, select "other" and specify a custom name)
  //     - "playing activity"
  //     - "study activity"
  //     - "household activity"
  //     - "other"

  // ⚡ IMPORTANT RULES:
  // - You must ALWAYS return all three fields: task, due_date, and category.
  // - If the due_date is missing, set it as "unknown". Do not ask the user for anything.
  // - Respond ONLY in pure JSON format like this:
  // {
  //   "task": "buy milk",
  //   "due_date": "28-09-2025",
  //   "category": "household activity"
  // }

  // User said: "$userSpeech"
  // """;

  //       final response = await http
  //           .post(
  //             url,
  //             headers: {'Content-Type': 'application/json'},
  //             body: jsonEncode({
  //               "model": "qwen2.5:1.5b",
  //               "prompt": fullPrompt,
  //               "stream": false,
  //               "options": {"temperature": 0.5, "max_tokens": 300},
  //             }),
  //           )
  //           .timeout(const Duration(seconds: 30));

  //       if (response.statusCode == 200) {
  //         final Map<String, dynamic> responseData = jsonDecode(response.body);
  //         final String aiResponse = responseData['response']?.trim() ?? "{}";

  //         try {
  //           _parsedResponse = jsonDecode(aiResponse);
  //         } catch (e) {
  //           _parsedResponse = {
  //             "task": "Failed to parse response",
  //             "due_date": "unknown",
  //             "category": "error",
  //           };
  //         }

  //         setState(() {
  //           _aiResponse = aiResponse;
  //           _isProcessing = false;
  //         });
  //       } else {
  //         throw Exception("API Error: ${response.statusCode}");
  //       }
  //     } catch (e) {
  //       setState(() {
  //         _aiResponse = "Error: ${e.toString()}";
  //         _isProcessing = false;
  //       });
  //     }
  //   }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: const Text(
          "Speech to Task Extractor",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Add connection status indicator
              if (_isCheckingConnection)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Checking internet connection...',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              Text(
                _isListening
                    ? "Listening... Speak now"
                    : _speechEnabled
                    ? "Tap the microphone to start"
                    : "Speech not available",
                style: const TextStyle(fontSize: 20.0, color: Colors.black54),
              ),
              const SizedBox(height: 20),

              _buildSpeechBubble(
                title: "You said:",
                content: _wordsSpoken.isEmpty ? "..." : _wordsSpoken,
                color: Colors.blueGrey.shade100,
              ),

              const SizedBox(height: 20),

              _buildSpeechBubble(
                title: "AI Response:",
                content:
                    _isProcessing
                        ? "Processing..."
                        : _aiResponse.isEmpty
                        ? "Waiting for your voice input..."
                        : _aiResponse,
                color: Colors.blue.shade50,
              ),

              if (_isProcessing)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: CircularProgressIndicator(),
                ),
              if (_parsedResponse != null && !_isProcessing)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_task),
                    label: const Text('Add Task'),
                    onPressed: _saveTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_aiResponse.isNotEmpty && !_isProcessing)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: FloatingActionButton(
                heroTag: 'confirmButton',
                onPressed: _saveTask,
                backgroundColor: Colors.green,
                child: const Icon(Icons.check, color: Colors.white),
              ),
            ),
          FloatingActionButton(
            heroTag: 'micButton',
            onPressed:
                _speechToText.isListening ? _stopListening : _startListening,
            tooltip:
                _speechToText.isListening
                    ? "Stop listening"
                    : "Start listening",
            backgroundColor:
                _speechToText.isListening ? Colors.red : Colors.blueGrey,
            child: Icon(
              _speechToText.isListening ? Icons.mic_off : Icons.mic,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeechBubble({
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 18, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
