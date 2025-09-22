import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/connectivity_service.dart';
import 'package:api_key_pool/api_key_pool.dart';
import '../utils/ai_config.dart';
import 'create_task_screen.dart';

class QuickAITaskScreen extends StatefulWidget {
  @override
  _QuickAITaskScreenState createState() => _QuickAITaskScreenState();
}

class _QuickAITaskScreenState extends State<QuickAITaskScreen> {
  final TextEditingController _taskController = TextEditingController();
  bool _isProcessing = false;
  bool _isCheckingConnection = false;
  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'AI Assistant',
          style: TextStyle(
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
                Color(0xFF1e40af),
                Color(0xFF1e3a8a),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1e3a8a),
              Color(0xFF3b82f6),
              Color(0xFF1e40af),
              Color(0xFF1d4ed8),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
          // Add connection status indicator
          if (_isCheckingConnection)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3b82f6), Color(0xFF1d4ed8)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3b82f6).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Checking internet connection...',
                    style: TextStyle(
                      color: Colors.white, 
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header Section
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFffffff), Color(0xFFf8f9fa)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3b82f6), Color(0xFF1d4ed8)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.psychology_outlined,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'AI Task Assistant',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Describe your task and let AI help you create it with smart suggestions',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    constraints: const BoxConstraints(
                      minHeight: 120,
                      maxHeight: 200,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFffffff), Color(0xFFf8f9fa)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _taskController,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2D3748),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Describe your task...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.all(20),
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3b82f6), Color(0xFF1d4ed8)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.psychology_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      maxLines: 4,
                      minLines: 3,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      minHeight: 56,
                    ),
                    decoration: BoxDecoration(
                      gradient: _isProcessing 
                          ? null 
                          : const LinearGradient(
                              colors: [Color(0xFF3b82f6), Color(0xFF1d4ed8)],
                            ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _isProcessing 
                          ? null 
                          : [
                              BoxShadow(
                                color: const Color(0xFF3b82f6).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _processAITask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isProcessing 
                            ? Colors.grey.shade400 
                            : Colors.transparent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isProcessing 
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Processing...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.psychology_outlined,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Process with AI',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24), // Bottom padding
                ],
              ),
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processAITask() async {
    if (_taskController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a task description'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _isCheckingConnection = true;
    });

    // Validate internet connection before processing
    final hasConnection = await _connectivityService.validateConnectionForAI(
      context,
      feature: "Quick AI Task Creation"
    );

    setState(() {
      _isCheckingConnection = false;
    });

    if (!hasConnection) {
      return;
    }

    try {
      setState(() {
        _isProcessing = true;
      });

      final apiKey = ApiKeyPool.getKey();
      if (apiKey.isEmpty) {
        throw Exception('API key not found. Please check your API key pool configuration.');
      }

      // Make AI API call
      final modelName = AIConfig.modelName;
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [{
            'parts': [{
              'text': 'Process this task request: "${_taskController.text}". Please provide a structured response in the following format:\n\nTitle: [extracted or improved task title]\nDescription: [detailed description of the task]\nCategory: [one of: academics, social, personal, health, work, finance, other]\nPriority: [one of: high, medium, low]\n\nMake sure to extract the most important information and organize it clearly.'
            }]
          }]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['candidates'][0]['content']['parts'][0]['text'];
        
        print('DEBUG: AI Response: $aiResponse');
        
        // Parse the AI response to extract structured data
        final taskData = _parseAIResponse(aiResponse, _taskController.text);
        
        print('DEBUG: Parsed task data: $taskData');
        
        // Validate the task data structure
        if (taskData['title'] == null || taskData['title'].toString().isEmpty) {
          print('DEBUG: Warning - title is empty, using original input');
          taskData['title'] = _taskController.text;
        }
        
        // Clear the text field
        _taskController.clear();
        
        // Add a small delay to ensure context is stable
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Navigate to CreateTaskScreen with the parsed data
        if (mounted) {
          print('DEBUG: Navigating to CreateTaskScreen with task data');
          try {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateTaskScreen(
                  aiGeneratedData: taskData,
                ),
              ),
            );
            print('DEBUG: Navigation result: $result');
            print('DEBUG: Successfully navigated to CreateTaskScreen');
          } catch (e) {
            print('DEBUG: Error navigating to CreateTaskScreen: $e');
            print('DEBUG: Stack trace: ${StackTrace.current}');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Navigation error: ${e.toString()}'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          }
        } else {
          print('DEBUG: Widget not mounted, skipping navigation');
        }

      } else {
        throw Exception('Failed to process task: ${response.statusCode}');
      }

    } catch (e) {
      // Handle network errors specifically
      if (_connectivityService.isNetworkError(e)) {
        _connectivityService.handleNetworkError(context, e);
      } else {
        // Handle other errors
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Map<String, dynamic> _parseAIResponse(String aiResponse, String originalInput) {
    try {
      print('DEBUG: Parsing AI response: $aiResponse');
      
      // Try to parse structured JSON response first
      if (aiResponse.trim().startsWith('{') && aiResponse.trim().endsWith('}')) {
        final parsed = jsonDecode(aiResponse);
        print('DEBUG: Parsed JSON response: $parsed');
        return {
          'title': parsed['title'] ?? originalInput,
          'description': parsed['description'] ?? '',
          'category': parsed['category'] ?? 'other',
          'priority': parsed['priority'] ?? 'medium',
          'due_date': DateTime.now().add(const Duration(days: 1)), // Default to tomorrow
          'is_reminder': false,
        };
      }
      
      // If not JSON, try to extract structured information from text
      final lines = aiResponse.split('\n');
      Map<String, dynamic> taskData = {
        'title': originalInput,
        'description': '',
        'category': 'other',
        'priority': 'medium',
        'due_date': DateTime.now().add(const Duration(days: 1)),
        'is_reminder': false,
      };
      
      for (String line in lines) {
        final lowerLine = line.toLowerCase().trim();
        if (lowerLine.contains('title:') || lowerLine.contains('task:')) {
          final titleMatch = RegExp(r'(title|task):\s*(.+)', caseSensitive: false).firstMatch(line);
          if (titleMatch != null) {
            taskData['title'] = titleMatch.group(2)?.trim() ?? originalInput;
          }
        } else if (lowerLine.contains('description:') || lowerLine.contains('details:')) {
          final descMatch = RegExp(r'(description|details):\s*(.+)', caseSensitive: false).firstMatch(line);
          if (descMatch != null) {
            taskData['description'] = descMatch.group(2)?.trim() ?? '';
          }
        } else if (lowerLine.contains('category:')) {
          final catMatch = RegExp(r'category:\s*(.+)', caseSensitive: false).firstMatch(line);
          if (catMatch != null) {
            final category = catMatch.group(1)?.trim().toLowerCase() ?? 'other';
            // Map common categories to our predefined ones
            if (['work', 'job', 'business', 'office'].contains(category)) {
              taskData['category'] = 'work';
            } else if (['study', 'school', 'university', 'academic', 'learning'].contains(category)) {
              taskData['category'] = 'academics';
            } else if (['health', 'medical', 'doctor', 'fitness', 'exercise'].contains(category)) {
              taskData['category'] = 'health';
            } else if (['money', 'finance', 'financial', 'budget', 'payment'].contains(category)) {
              taskData['category'] = 'finance';
            } else if (['social', 'friend', 'family', 'relationship'].contains(category)) {
              taskData['category'] = 'social';
            } else if (['personal', 'self', 'private'].contains(category)) {
              taskData['category'] = 'personal';
            } else {
              taskData['category'] = 'other';
            }
          }
        } else if (lowerLine.contains('priority:')) {
          final priMatch = RegExp(r'priority:\s*(.+)', caseSensitive: false).firstMatch(line);
          if (priMatch != null) {
            final priority = priMatch.group(1)?.trim().toLowerCase() ?? 'medium';
            if (['high', 'urgent', 'important'].contains(priority)) {
              taskData['priority'] = 'high';
            } else if (['low', 'minor'].contains(priority)) {
              taskData['priority'] = 'low';
            } else {
              taskData['priority'] = 'medium';
            }
          }
        }
      }
      
      // If description is empty, use the AI response as description
      if (taskData['description'].toString().isEmpty && aiResponse.length > 50) {
        taskData['description'] = aiResponse;
      }
      
      print('DEBUG: Final parsed task data: $taskData');
      return taskData;
      
    } catch (e) {
      print('DEBUG: Error parsing AI response: $e');
      // Fallback to basic parsing
      return {
        'title': originalInput,
        'description': aiResponse.length > 200 ? aiResponse.substring(0, 200) + '...' : aiResponse,
        'category': 'other',
        'priority': 'medium',
        'due_date': DateTime.now().add(const Duration(days: 1)),
        'is_reminder': false,
      };
    }
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }
}