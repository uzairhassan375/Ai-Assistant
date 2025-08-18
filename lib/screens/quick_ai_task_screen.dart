import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/connectivity_service.dart';

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
      appBar: AppBar(
        title: Text('Quick AI Task'),
      ),
      body: Column(
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _taskController,
                    decoration: InputDecoration(
                      hintText: 'Enter your task here',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isProcessing ? null : _processAITask,
                    child: _isProcessing 
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 8),
                              Text('Processing...'),
                            ],
                          )
                        : Text('Process Task'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processAITask() async {
    if (_taskController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task description')),
      );
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

      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API key not found. Please check your .env file.');
      }

      // Make AI API call
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [{
            'parts': [{
              'text': 'Process this task request: "${_taskController.text}". Please provide a structured response with title, description, and suggested category.'
            }]
          }]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Task processed: $aiResponse'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Clear the text field
        _taskController.clear();

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

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }
}