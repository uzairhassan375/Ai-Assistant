import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'dart:io';

/// Simple time management service for scheduling and tracking notifications
class SimpleTimeManager {
  static final SimpleTimeManager _instance = SimpleTimeManager._internal();
  factory SimpleTimeManager() => _instance;
  SimpleTimeManager._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initialize the time manager
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize timezone
      tz.initializeTimeZones();
      
      // Initialize notifications
      const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final bool? initialized = await _notifications.initialize(initSettings);
      
      // Request permissions
      if (Platform.isAndroid) {
        final androidImplementation = _notifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidImplementation != null) {
          final bool? granted = await androidImplementation.requestNotificationsPermission();
          
          // Also request exact alarm permission for Android 12+
          final bool? exactAlarmGranted = await androidImplementation.requestExactAlarmsPermission();
        }
      }

      _initialized = true;
    } catch (e) {
      // Handle initialization error silently
    }
  }

  /// Schedule a notification for a specific time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? customSound,
    bool isAlarm = false,
  }) async {
    if (!_initialized) {
      return;
    }

    try {
      final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);
      
      // Use default sound instead of custom sounds for now
      final androidDetails = AndroidNotificationDetails(
        'task_reminders',
        'Task Reminders',
        channelDescription: 'Notifications for task reminders',
        importance: isAlarm ? Importance.max : Importance.high,
        priority: isAlarm ? Priority.max : Priority.high,
        playSound: true,
        enableVibration: true,
        category: isAlarm ? AndroidNotificationCategory.alarm : AndroidNotificationCategory.reminder,
        icon: '@drawable/ic_task_notification',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      );
      
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: isAlarm ? InterruptionLevel.critical : InterruptionLevel.timeSensitive,
      );
      
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      
    } catch (e) {
      // Handle scheduling error silently
    }
  }

  /// Show an immediate notification
  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_initialized) {
      return;
    }

    try {
      
      final androidDetails = AndroidNotificationDetails(
        'immediate_notifications',
        'Immediate Notifications',
        channelDescription: 'Immediate notifications for testing',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.message,
        icon: '@drawable/ic_notification',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical,
      );
      
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(id, title, body, notificationDetails);
      
    } catch (e) {
      // Handle notification error silently
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
    } catch (e) {
      // Handle cancellation error silently
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      // Handle cancellation error silently
    }
  }

  /// Get pending notification count
  Future<int> getPendingCount() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();
      return pending.length;
    } catch (e) {
      return 0;
    }
  }

  /// Generate a simple ID from task title
  int generateId(String taskTitle) {
    return taskTitle.hashCode.abs() % 1000000;
  }
}
