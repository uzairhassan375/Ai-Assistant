import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class VoiceCommandScreen extends StatefulWidget {
  @override
  _VoiceCommandScreenState createState() => _VoiceCommandScreenState();
}

class _VoiceCommandScreenState extends State<VoiceCommandScreen> {
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isProcessing = false;
  bool _isCheckingConnection = false;
  
  // Add speech to text variables
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = '';
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voice Command'),
      ),
      body: Column(
        children: [
          _buildConnectionStatus(),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      _text.isEmpty ? 'Tap the microphone and start speaking' : _text,
                      style: TextStyle(
                        fontSize: 24.0,
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 30),
                  FloatingActionButton(
                    onPressed: _listen,
                    child: Icon(_isListening ? Icons.mic : Icons.mic_none),
                    backgroundColor: _isListening ? Colors.red : Colors.blue,
                  ),
                  if (_isProcessing)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => {},
        onError: (val) => {},
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _lastWords = val.recognizedWords;
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      
      // Process the voice command after stopping
      if (_lastWords.isNotEmpty) {
        await _processVoiceCommand(_lastWords);
      }
    }
  }

  Future<void> _processVoiceCommand(String command) async {
    if (command.trim().isEmpty) return;

    setState(() {
      _isCheckingConnection = true;
    });

    // Check internet connection first
    final hasConnection = await _connectivityService.validateConnectionForAI(
      context, 
      feature: "Voice AI Commands"
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

    try {
      setState(() {
        _isProcessing = true;
      });

      // Make the AI API call
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=${dotenv.env['GEMINI_API_KEY']}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [{
            'parts': [{
              'text': 'Convert this voice command into a structured task: "$command". Please provide a clear task title and description.'
            }]
          }]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final generatedTask = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Task created from voice command: $generatedTask'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Clear the text after processing
        setState(() {
          _text = '';
          _lastWords = '';
        });

      } else {
        throw Exception('Failed to process voice command: ${response.statusCode}');
      }

    } catch (error) {
      if (_connectivityService.isNetworkError(error)) {
        _connectivityService.handleNetworkError(context, error);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error processing voice command: ${error.toString()}'),
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

  Widget _buildConnectionStatus() {
    if (_isCheckingConnection) {
      return Container(
        padding: const EdgeInsets.all(8),
        color: Colors.orange,
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
      );
    }
    return const SizedBox.shrink();
  }
}