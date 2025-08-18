import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static GlobalKey<NavigatorState>? navigatorKey;

  Future<void> init() async {
    // Disabled for demo release
    return;
  }

  Future<void> scheduleReminderNotification({
    required int id,
    required String title,
    required String body,
    required DateTime dueDate,
    String? taskId,
  }) async {
    // Disabled for demo release
    return;
  }

  Future<void> cancelNotification(int id) async {
    // Disabled for demo release
    return;
  }

  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // Disabled for demo release
    if (kIsWeb) return;
  }

  Future<void> scheduleTestNotification({
    required String title,
    required String body,
  }) async {
    // Disabled for demo release
    return;
  }

  Future<int> getScheduledNotificationCount() async {
    return 0;
  }

  Future<void> clearAllNotifications() async {
    // Disabled for demo release
    return;
  }

  Future<void> scheduleTaskDeadlineNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String taskId,
  }) async {
    // Disabled for demo release
    return;
  }

  int generateNotificationId(String taskId) {
    int hash = 0;
    for (int i = 0; i < taskId.length; i++) {
      hash = ((hash << 5) - hash) + taskId.codeUnitAt(i);
      hash = hash & hash;
    }
    return hash.abs() % 2147483647;
  }

  Future<List<dynamic>> getPendingNotifications() async {
    return [];
  }
}
