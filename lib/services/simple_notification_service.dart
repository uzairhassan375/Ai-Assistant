import 'package:aiassistant1/models/task.dart';
import 'package:aiassistant1/services/simple_time_manager.dart';

/// Simple notification service for showing and managing notifications
class SimpleNotificationService {
  static final SimpleNotificationService _instance = SimpleNotificationService._internal();
  factory SimpleNotificationService() => _instance;
  SimpleNotificationService._internal();

  final SimpleTimeManager _timeManager = SimpleTimeManager();

  // Custom notification icon configuration
  static const String notificationIcon = '@drawable/ic_stat_notify';
  static const String largeNotificationIcon = '@mipmap/ic_launcher';

  /// Initialize the notification service
  Future<void> initialize() async {
    await _timeManager.initialize();
  }

  /// Schedule a task reminder notification
  Future<void> scheduleTaskReminder(Task task) async {
    if (!task.isReminder || task.isCompleted) {
      return;
    }

    final now = DateTime.now();
    if (task.dueDate.isBefore(now)) {
      return;
    }

    final notificationId = _timeManager.generateId(task.title);
    
    await _timeManager.scheduleNotification(
      id: notificationId,
      title: '📋 Task Reminder',
      body: '${task.title} is due now!',
      scheduledTime: task.dueDate,
      isAlarm: true, // Use alarm sound for task reminders
    );
  }

  /// Cancel a task reminder
  Future<void> cancelTaskReminder(Task task) async {
    final notificationId = _timeManager.generateId(task.title);
    await _timeManager.cancelNotification(notificationId);
  }

  /// Show an immediate notification
  Future<void> showImmediateNotification({
    required String title,
    required String body,
  }) async {
    final notificationId = DateTime.now().millisecondsSinceEpoch % 1000000;
    
    await _timeManager.scheduleNotification(
      id: notificationId,
      title: title,
      body: body,
      scheduledTime: DateTime.now().add(const Duration(seconds: 1)),
    );
  }




  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _timeManager.cancelAllNotifications();
  }

  /// Get pending notification count
  Future<int> getPendingCount() async {
    return await _timeManager.getPendingCount();
  }

  /// Cancel notification by ID (for internal use)
  Future<void> cancelNotificationById(int notificationId) async {
    await _timeManager.cancelNotification(notificationId);
  }

  /// Note: Custom notification icon is configured in SimpleTimeManager
  /// All notifications will use the icon: @drawable/ic_stat_notify
  /// This is set in both Android initialization and notification details

  /// Schedule multiple reminders for a task (5 minutes before, at due time, 5 minutes after)
  Future<void> scheduleMultipleReminders(Task task) async {
    if (!task.isReminder || task.isCompleted) return;

    final baseId = _timeManager.generateId(task.title);
    final dueTime = task.dueDate;

    // 5 minutes before
    final beforeTime = dueTime.subtract(const Duration(minutes: 5));
    if (beforeTime.isAfter(DateTime.now())) {
      await _timeManager.scheduleNotification(
        id: baseId + 1,
        title: '⏰ Task Due Soon',
        body: '${task.title} is due in 5 minutes',
        scheduledTime: beforeTime,
        isAlarm: false, // Gentle reminder sound
      );
    }

    // At due time
    await _timeManager.scheduleNotification(
      id: baseId,
      title: '📋 Task Due Now',
      body: '${task.title} is due now!',
      scheduledTime: dueTime,
      isAlarm: true, // Alarm sound for due time
    );

    // 5 minutes after (overdue)
    final afterTime = dueTime.add(const Duration(minutes: 5));
    await _timeManager.scheduleNotification(
      id: baseId + 2,
      title: '🚨 Task Overdue',
      body: '${task.title} is overdue!',
      scheduledTime: afterTime,
      isAlarm: true, // Alarm sound for overdue
    );
  }
}
