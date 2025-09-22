import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:aiassistant1/models/task.dart';
import 'package:aiassistant1/services/task_services.dart';
import 'package:aiassistant1/services/simple_notification_service.dart';
import '../services/connectivity_service.dart';
import '../utils/ai_config.dart';
import 'package:api_key_pool/api_key_pool.dart';

class VoiceTaskCreationScreen extends StatefulWidget {
  const VoiceTaskCreationScreen({super.key});

  @override
  State<VoiceTaskCreationScreen> createState() => _VoiceTaskCreationScreenState();
}

class _VoiceTaskCreationScreenState extends State<VoiceTaskCreationScreen> {
  final SpeechToText _speechToText = SpeechToText();
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _speechEnabled = false;
  String _wordsSpoken = "";
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isSaving = false;
  bool _isCheckingConnection = false;
  Map<String, dynamic>? _parsedResponse;
  String _originalUserInput = "";
  String? _userFeedback; // Track user's feedback on AI response

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
    super.dispose();
  }

  void _startListening() async {
    setState(() {
      _isListening = true;
      _wordsSpoken = "";
      _parsedResponse = null;
    });
    
    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
    );
  }

  void _stopListening() async {
    setState(() {
      _isListening = false;
    });
    await _speechToText.stop();
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _wordsSpoken = result.recognizedWords;
    });

    if (result.finalResult) {
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
    // Check internet connection BEFORE making API call
    setState(() {
      _isCheckingConnection = true;
    });

    final hasConnection = await _connectivityService.validateConnectionForAI(
      context,
      feature: "Voice Task Creation",
    );

    setState(() {
      _isCheckingConnection = false;
    });

    if (!hasConnection) {
      setState(() {
        _isProcessing = false;
      });
      return;
    }

    final apiKey = ApiKeyPool.getKey();
    if (apiKey.isEmpty) {
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
      final modelName = AIConfig.modelName;
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey',
      );

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
      } else {
        throw Exception(
          "Gemini API Error: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      // Handle network errors specifically
      if (_connectivityService.isNetworkError(e)) {
        _connectivityService.handleNetworkError(context, e);
      } else {
        setState(() {
          _isProcessing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  void _tryAgain() {
    setState(() {
      _wordsSpoken = "";
      _parsedResponse = null;
      _isProcessing = false;
      _userFeedback = null; // Reset feedback
    });
    _startListening();
  }

  void _showFeedbackSnackBar(bool isLike) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isLike ? Icons.thumb_up : Icons.thumb_down,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isLike 
                  ? 'Thanks for the positive feedback! 👍'
                  : 'Thanks for the feedback. We\'ll improve! 👎',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isLike ? Colors.green[600] : Colors.orange[600],
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

  Future<void> _saveTask() async {
    if (_parsedResponse == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    const String demoUserId = 'demo_user';

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
        userId: demoUserId,
        category: _parsedResponse!['category'],
        priority: TaskPriority.medium,
        isReminder: isReminderTask,
        isCompleted: false,
        isArchived: false,
        subtasks: [],
      );

      final createdTask = await taskService.createTask(task);
      
      // Schedule notification if reminder is enabled
      if (task.isReminder) {
        final notificationService = SimpleNotificationService();
        await notificationService.scheduleTaskReminder(task);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task created successfully!')),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
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

  // Modern UI Helper Methods
  Widget _buildAnimatedMicIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.2),
      duration: const Duration(milliseconds: 1000),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.mic,
              size: 48,
              color: Colors.red,
            ),
          ),
        );
      },
      onEnd: () {
        // Reverse animation
        setState(() {});
      },
    );
  }

  Widget _buildSpeechContainer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.format_quote,
                color: Colors.grey[500],
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'What you\'re saying:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _wordsSpoken.isEmpty ? 'Listening for your voice...' : _wordsSpoken,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _wordsSpoken.isEmpty ? Colors.grey[500] : Colors.black87,
              fontStyle: _wordsSpoken.isEmpty ? FontStyle.italic : FontStyle.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStopButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _stopListening,
        icon: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(
            Icons.stop,
            size: 18,
            color: Colors.white,
          ),
        ),
        label: const Text(
          'Stop Listening',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: Colors.red.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingAnimation() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 2000),
      builder: (context, value, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 4,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                  backgroundColor: Colors.deepPurple.withOpacity(0.2),
                ),
              ),
              const Icon(
                Icons.psychology,
                size: 30,
                color: Colors.deepPurple,
              ),
            ],
          ),
        );
      },
      onEnd: () {
        setState(() {});
      },
    );
  }

  Widget _buildQuoteContainer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.deepPurple.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.format_quote,
            color: Colors.deepPurple,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '"$_wordsSpoken"',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(50),
      ),
      child: const Icon(
        Icons.check_circle_outline,
        size: 48,
        color: Colors.green,
      ),
    );
  }

  Widget _buildModernTaskPreview() {
    if (_parsedResponse == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.task_alt,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Task Preview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildModernPreviewRow('Title', _parsedResponse!['task'] ?? '', Icons.title),
          _buildModernPreviewRow('Due Date', _parsedResponse!['due_date'] ?? '', Icons.calendar_today),
          _buildModernPreviewRow('Due Time', _parsedResponse!['due_time'] ?? 'Not specified', Icons.access_time),
          _buildModernPreviewRow('Category', _parsedResponse!['category'] ?? '', Icons.category),
          
          // Feedback section
          const SizedBox(height: 20),
          const Divider(color: Colors.grey),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.feedback_outlined,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                'How is this AI response?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Like button
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _userFeedback = 'like';
                    });
                    _showFeedbackSnackBar(true);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: _userFeedback == 'like' ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _userFeedback == 'like' ? Colors.green : Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.thumb_up_outlined,
                          size: 16,
                          color: _userFeedback == 'like' ? Colors.green : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Good',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _userFeedback == 'like' ? Colors.green : Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Dislike button
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _userFeedback = 'dislike';
                    });
                    _showFeedbackSnackBar(false);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: _userFeedback == 'dislike' ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _userFeedback == 'dislike' ? Colors.red : Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.thumb_down_outlined,
                          size: 16,
                          color: _userFeedback == 'dislike' ? Colors.red : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Needs work',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _userFeedback == 'dislike' ? Colors.red : Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernPreviewRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveTask,
            icon: _isSaving
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.save,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
            label: Text(
              _isSaving ? 'Saving Task...' : 'Save Task',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              elevation: 6,
              shadowColor: Colors.deepPurple.withOpacity(0.3),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isSaving ? null : _tryAgain,
            icon: const Icon(
              Icons.refresh,
              size: 18,
            ),
            label: const Text(
              'Try Again',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
              side: BorderSide(color: Colors.grey[300]!),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadyIcon() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(50),
      ),
      child: const Icon(
        Icons.mic_none,
        size: 48,
        color: Colors.deepPurple,
      ),
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _speechEnabled ? _startListening : null,
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.mic,
            size: 20,
            color: Colors.white,
          ),
        ),
        label: const Text(
          'Start Voice Input',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: Colors.deepPurple.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.blue[600],
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Tips for better results:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Speak clearly and mention the task\n• Include due date if needed\n• Specify category (work, personal, etc.)',
            style: TextStyle(
              fontSize: 13,
              color: Colors.blue[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Voice Task Creator',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Gradient Header
          Container(
            height: _isCheckingConnection ? 140 : 120,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.deepPurple,
                  Color(0xFF7B1FA2),
                ],
              ),
            ),
            child: Column(
              children: [
                // Add connection status indicator
                if (_isCheckingConnection)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
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
                          'Checking connection...',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Icon(
                            _getStatusIcon(),
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getStatusText(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Main Content
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -30),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      
                      // Main Content Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _buildMainContent(),
                      ),
                      
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon() {
    if (_isListening) return Icons.mic;
    if (_isProcessing) return Icons.psychology;
    if (_parsedResponse != null) return Icons.check_circle_outline;
    return Icons.mic_none;
  }

  String _getStatusText() {
    if (_isListening) return 'Listening...';
    if (_isProcessing) return 'Processing...';
    if (_parsedResponse != null) return 'Task Ready';
    return 'Voice Input';
  }

  Widget _buildMainContent() {
    // Listening state
    if (_isListening) {
      return Column(
        children: [
          _buildAnimatedMicIcon(),
          const SizedBox(height: 24),
          const Text(
            'I\'m listening...',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Speak clearly about your task',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          _buildSpeechContainer(),
          const SizedBox(height: 24),
          _buildStopButton(),
        ],
      );
    }
    
    // Processing state
    else if (_isProcessing) {
      return Column(
        children: [
          _buildProcessingAnimation(),
          const SizedBox(height: 24),
          const Text(
            'Creating your task...',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Analyzing what you said',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          _buildQuoteContainer(),
        ],
      );
    }
    
    // Task preview state
    else if (_parsedResponse != null) {
      return Column(
        children: [
          _buildSuccessIcon(),
          const SizedBox(height: 24),
          const Text(
            'Task Created Successfully!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review and save your task',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          _buildModernTaskPreview(),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      );
    }
    
    // Initial/Ready state
    else {
      return Column(
        children: [
          _buildReadyIcon(),
          const SizedBox(height: 24),
          const Text(
            'Ready to Create Task',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button and describe your task',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          _buildStartButton(),
          const SizedBox(height: 20),
          _buildTipsCard(),
        ],
      );
    }
  }
}
