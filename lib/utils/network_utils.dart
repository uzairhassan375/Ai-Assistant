import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

class NetworkUtils {
  static final ConnectivityService _connectivityService = ConnectivityService();

  /// Wrapper for AI API calls with automatic connectivity checking and error handling
  static Future<T?> executeWithConnectivityCheck<T>(
    BuildContext context,
    Future<T> Function() apiCall, {
    String feature = "AI Voice Command",
    Function()? onConnectionFailed,
  }) async {
    // Check connection before making the API call
    final hasConnection = await _connectivityService.validateConnectionForAI(
      context, 
      feature: feature
    );
    
    if (!hasConnection) {
      onConnectionFailed?.call();
      return null;
    }

    try {
      // Execute the API call
      return await apiCall();
    } catch (error) {
      // Handle network-specific errors
      if (_connectivityService.isNetworkError(error)) {
        if (context.mounted) {
          _connectivityService.handleNetworkError(context, error);
        }
      } else {
        // Re-throw non-network errors for specific handling
        rethrow;
      }
      return null;
    }
  }

  /// Check if error is network related and show appropriate message
  static void handleError(BuildContext context, dynamic error) {
    if (_connectivityService.isNetworkError(error)) {
      _connectivityService.handleNetworkError(context, error);
    } else {
      // Show generic error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
