import 'package:flutter/services.dart';

class AndroidNotificationHelper {
  static const MethodChannel _channel = 
      MethodChannel('com.example.aiassistant1/notifications');

  /// Clear any corrupted notification data that might cause TypeToken issues
  static Future<void> clearCorruptedNotifications() async {
    try {
      await _channel.invokeMethod('clearCorruptedNotifications');
    } catch (e) {
      print('Failed to clear corrupted notifications: $e');
    }
  }

  /// Get the count of currently scheduled notifications
  static Future<int> getScheduledNotificationCount() async {
    try {
      final count = await _channel.invokeMethod('getScheduledNotificationCount');
      return count ?? 0;
    } catch (e) {
      print('Failed to get notification count: $e');
      return 0;
    }
  }
}
