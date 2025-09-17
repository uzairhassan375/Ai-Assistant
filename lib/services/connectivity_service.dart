import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();

  Future<bool> hasInternetConnection() async {
    try {
      // First check network connectivity
      final List<ConnectivityResult> connectivityResult =
          await _connectivity.checkConnectivity();

      bool hasNetworkConnection = connectivityResult.any((result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet);

      if (!hasNetworkConnection) {
        return false;
      }

      // Test actual internet access with Google APIs
      try {
        final result = await InternetAddress.lookup('generativelanguage.googleapis.com')
            .timeout(const Duration(seconds: 3));
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          return true;
        }
      } catch (e) {
        // If Google API host fails, try fallback
        try {
          final fallbackResult = await InternetAddress.lookup('google.com')
              .timeout(const Duration(seconds: 3));
          return fallbackResult.isNotEmpty && fallbackResult[0].rawAddress.isNotEmpty;
        } catch (e) {
          return false;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> validateConnectionForAI(BuildContext context, {String feature = "AI"}) async {
    final hasConnection = await hasInternetConnection();

    if (!hasConnection) {
      if (context.mounted) {
        _showNoInternetDialog(context, feature);
      }
      return false;
    }
    return true;
  }

  bool isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socketexception') ||
        errorString.contains('clientexception') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('no address associated with hostname') ||
        errorString.contains('generativelanguage.googleapis.com') ||
        errorString.contains('network is unreachable') ||
        errorString.contains('connection refused') ||
        errorString.contains('connection timeout') ||
        errorString.contains('connection timed out');
  }

  void handleNetworkError(BuildContext context, dynamic error) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.signal_wifi_connected_no_internet_4, color: Colors.red),
              SizedBox(width: 8),
              Text('Connection Failed'),
            ],
          ),
          content: const Text(
            'Unable to connect to AI services. Please check your internet connection and try again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showNoInternetDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.red, size: 24),
              SizedBox(width: 12),
              Expanded(child: Text('No Internet Connection')),
            ],
          ),
          content: Text(
            '$feature requires an active internet connection. Please turn on your internet and try again.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Future.delayed(const Duration(milliseconds: 500));
                final hasConnection = await hasInternetConnection();
                if (hasConnection && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.wifi, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Internet connection restored!'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else if (context.mounted) {
                  _showNoInternetDialog(context, feature);
                }
              },
              child: const Text('Check Again'),
            ),
          ],
        );
      },
    );
  }

  void showConnectionRestoredMessage(BuildContext context) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi, color: Colors.white),
              SizedBox(width: 8),
              Text('Internet connected!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
