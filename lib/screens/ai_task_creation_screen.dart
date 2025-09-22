import 'package:flutter/material.dart';
// Removed speech-to-text imports as they're no longer needed
// import 'package:speech_to_text/speech_recognition_result.dart';
// import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/connectivity_service.dart';
import '../utils/ai_config.dart';
import 'package:api_key_pool/api_key_pool.dart';

class AITaskCreationScreen extends StatefulWidget {
  final String? existingTitle;
  final String? existingCategory;
  final DateTime? existingDueDate;
  final String? existingDescription;
  
  const AITaskCreationScreen({
    super.key,
    this.existingTitle,
    this.existingCategory,
    this.existingDueDate,
    this.existingDescription,
  });

  @override
  State<AITaskCreationScreen> createState() => _AITaskCreationScreenState();
}

class _AITaskCreationScreenState extends State<AITaskCreationScreen> {
  final _quickInputController = TextEditingController();
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isProcessing = false;
  bool _isSaving = false;
  bool _isCheckingConnection = false;
  Map<String, dynamic>? _parsedResponse;
  String _originalUserInput = ""; // Store the original user input to determine task type
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
    // Check internet connection BEFORE making API call
    setState(() {
      _isCheckingConnection = true;
    });

    final hasConnection = await _connectivityService.validateConnectionForAI(
      context,
      feature: "AI Task Creation",
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

    // Store the original user input to determine task type later
    _originalUserInput = userSpeech;
    
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
            behavior: SnackBarBehavior.fixed,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
          ),
        );
      }
      return;
    }
    
    final modelName = 'models/${AIConfig.modelName}';

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
2. Description: A brief description or additional details about the task (can be empty if not mentioned)
3. Due Date: Extract the date in DD-MM-YYYY format. If no specific date is mentioned:
   - If they say "today", use today's date
   - If they say "tomorrow", use tomorrow's date
   - If they say "next week", use 7 days from today
   - If no date is mentioned, use "unknown"
4. Due Time: Extract the time in HH:MM (24-hour) format. If no time is mentioned, use "00:00"
5. Category: Choose the most appropriate category from:
   - "academics" (for study, homework, research, etc.)
   - "social" (for meetings, events, gatherings, etc.)
   - "personal" (for personal tasks, hobbies, etc.)
   - "health" (for exercise, medical appointments, etc.)
   - "work" (for work-related tasks, projects, etc.)
   - "finance" (for bills, payments, budgeting, etc.)
   - "other" (if none of the above fit)
6. Priority: Determine the urgency level from:
   - "low" (for non-urgent tasks)
   - "medium" (for normal tasks - default)
   - "high" (for important/urgent tasks)
   - "urgent" (for critical/immediate tasks)

⚡ IMPORTANT RULES:
- The task title should be clear and specific
- Description can be empty string if no details are mentioned
- The due date must be in DD-MM-YYYY format
- The due time must be in HH:MM format
- The category must be one of the exact values listed above
- The priority must be one of the exact values listed above
- If any information is unclear, make a reasonable assumption
- Respond ONLY in pure JSON format like this:
{
  "task": "Complete project report",
  "description": "Finish the quarterly report with charts and analysis",
  "due_date": "28-09-2024",
  "due_time": "17:30",
  "category": "work",
  "priority": "high"
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
              SnackBar(
                content: Text('Error parsing response: ${e.toString()}'),
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
      // Handle network errors specifically
      if (_connectivityService.isNetworkError(e)) {
        _connectivityService.handleNetworkError(context, e);
      } else {
        setState(() {
          _isProcessing = false;
        });
        if (mounted) {
          // Don't close the screen on error - show error and let user try again
          // Navigator.of(context).pop(); // Close dialog on error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
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
      print('DEBUG: _parsedResponse is null, returning early');
      return;
    }

    print('DEBUG: Starting _saveTask with response: $_parsedResponse');
    setState(() {
      _isSaving = true;
    });

    try {
      // Parse date and time
      DateTime? parsedDueDate;
      
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
              parsedDueDate = DateTime(year, month, day, hour, minute);
            }
          }
          } catch (e) {
          // Handle date parsing error
        }
      }

      // Determine if this is a reminder based on the original user input
      final isReminderTask = _originalUserInput.toLowerCase().contains('remind') || 
                            _originalUserInput.toLowerCase().contains('reminder');

      // Create a data map to return to the Create Task screen
      final taskData = {
        'title': widget.existingTitle?.isNotEmpty == true 
            ? widget.existingTitle 
            : _parsedResponse!['task'].toString(),
        'category': widget.existingCategory?.isNotEmpty == true && widget.existingCategory != 'other'
            ? widget.existingCategory
            : _parsedResponse!['category'],
        'due_date': widget.existingDueDate != null 
            ? widget.existingDueDate 
            : parsedDueDate,
        'is_reminder': isReminderTask,
        'description': widget.existingDescription?.isNotEmpty == true 
            ? widget.existingDescription 
            : (_parsedResponse!['description']?.toString().isNotEmpty == true 
                ? _parsedResponse!['description'].toString() 
                : null),
        'priority': _parsedResponse!['priority'] ?? 'medium',
      };

      print('DEBUG: Created taskData: $taskData');

      if (mounted) {
        print('DEBUG: About to navigate back with taskData');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task data ready!'),
            behavior: SnackBarBehavior.fixed,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
          ),
        );
        print('DEBUG: Calling Navigator.pop with taskData');
        Navigator.of(context).pop(taskData); // Return parsed data instead of creating task
        print('DEBUG: Navigator.pop completed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process task data: $e'),
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
            if (_parsedResponse!['description'] != null && _parsedResponse!['description'].toString().isNotEmpty)
              _buildPreviewItem('Description', _parsedResponse!['description']),
            _buildPreviewItem('Due Date', _parsedResponse!['due_date'] ?? 'Unknown'),
            _buildPreviewItem('Time', _parsedResponse!['due_time'] ?? '00:00'),
            _buildPreviewItem('Category', _parsedResponse!['category'] ?? 'other'),
            _buildPreviewItem('Priority', _parsedResponse!['priority'] ?? 'medium'),
            
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
                    label: Text(_isSaving ? 'Processing...' : 'Use This Data'),
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
                      _userFeedback = null; // Reset feedback
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
            // Add connection status indicator
            if (_isCheckingConnection)
              Container(
                margin: const EdgeInsets.all(16),
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
