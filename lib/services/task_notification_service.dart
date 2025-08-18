import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/material.dart';
import 'package:aiassistant1/models/task.dart';
import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

class TaskNotificationService {
  static final TaskNotificationService _instance = TaskNotificationService._internal();
  factory TaskNotificationService() => _instance;
  TaskNotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  bool _initialized = false;

  /// Initialize the notification service with timezone support
  Future<void> initialize() async {
    // Disabled for demo release
    return;
  }

  /// Get local timezone
  Future<String> _getLocalTimeZone() async {
    try {
      // Map common timezone names to proper identifiers
      final String systemTimeZone = DateTime.now().timeZoneName;
      print('TaskNotificationService: System timezone: $systemTimeZone');
      
      // Common timezone mappings
      const Map<String, String> timeZoneMap = {
        'PKT': 'Asia/Karachi',
        'PST': 'America/Los_Angeles',
        'EST': 'America/New_York',
        'GMT': 'UTC',
        'IST': 'Asia/Kolkata',
        'JST': 'Asia/Tokyo',
        'CET': 'Europe/Paris',
        'UTC': 'UTC',
      };
      
      // Try to map the system timezone to a proper identifier
      String properTimeZone = timeZoneMap[systemTimeZone] ?? 'UTC';
      
      // Try to validate the timezone exists
      try {
        tz.getLocation(properTimeZone);
        print('TaskNotificationService: Using timezone: $properTimeZone');
        return properTimeZone;
      } catch (e) {
        print('TaskNotificationService: Timezone $properTimeZone not found, using UTC');
        return 'UTC';
      }
    } catch (e) {
      print('TaskNotificationService: Could not determine timezone, using UTC: $e');
      return 'UTC';
    }
  }

  /// Initialize the notification plugin
  Future<void> _initializeNotificationPlugin() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      print('TaskNotificationService: Notification tapped with payload: $payload');
      // Handle notification tap - you can navigate to specific task here
    }
  }

  /// Request notification permissions
  Future<bool> requestNotificationPermissions() async {
    // Disabled for demo release
    return false;
  }

  /// Create notification channels for better organization
  Future<void> _createNotificationChannels() async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      // Task deadline channel - highest priority
      const AndroidNotificationChannel taskDeadlineChannel = AndroidNotificationChannel(
        'task_deadline_channel',
        'Task Deadlines',
        description: 'Notifications for task due dates and deadlines',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
        enableLights: true,
        ledColor: Color(0xFF4CAF50),
      );

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(taskDeadlineChannel);

      print('TaskNotificationService: Created notification channels');
    } catch (e) {
      print('TaskNotificationService: Error creating channels: $e');
    }
  }

  /// Enhanced task notification scheduling with multiple reliability mechanisms
  Future<void> scheduleTaskNotification(Task task) async {
    // Disabled for demo release
    return;
  }

  /// Schedule multiple notifications with different strategies for maximum reliability
  Future<void> _scheduleReliableNotifications(Task task, tz.TZDateTime scheduledDate, int baseId) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      int scheduledCount = 0;
      
      // Strategy 1: exactAllowWhileIdle (main notification at exact time)
      if (scheduledDate.isAfter(now)) {
        await _scheduleNotificationWithStrategy(
          task, scheduledDate, baseId, 
          AndroidScheduleMode.exactAllowWhileIdle,
          isMain: true,
          titlePrefix: '🔔 '
        );
        scheduledCount++;
      }
      
      // Strategy 2: Pre-notification 30 seconds before (to wake the system)
      final preNotificationTime = scheduledDate.subtract(const Duration(seconds: 30));
      if (preNotificationTime.isAfter(now)) {
        await _scheduleNotificationWithStrategy(
          task, preNotificationTime, baseId + 1, 
          AndroidScheduleMode.exactAllowWhileIdle,
          isMain: false,
          titlePrefix: '⏰ APPROACHING: ',
          isPreNotification: true
        );
        scheduledCount++;
      }
      
      // Strategy 3: Backup exact mode notification 1 minute after
      final backup1Time = scheduledDate.add(const Duration(minutes: 1));
      if (backup1Time.isAfter(now)) {
        await _scheduleNotificationWithStrategy(
          task, backup1Time, baseId + 2, 
          AndroidScheduleMode.exact,
          isMain: false,
          titlePrefix: '📢 REMINDER: '
        );
        scheduledCount++;
      }
      
      // Strategy 4: Critical alarm notification 2 minutes after (highest priority)
      final backup2Time = scheduledDate.add(const Duration(minutes: 2));
      if (backup2Time.isAfter(now)) {
        await _scheduleNotificationWithStrategy(
          task, backup2Time, baseId + 3, 
          AndroidScheduleMode.exactAllowWhileIdle,
          isMain: false,
          titlePrefix: '🚨 OVERDUE: ',
          isCritical: true
        );
        scheduledCount++;
      }
      
      // Strategy 5: Final fallback inexact notification 5 minutes after
      final backup3Time = scheduledDate.add(const Duration(minutes: 5));
      if (backup3Time.isAfter(now)) {
        await _scheduleNotificationWithStrategy(
          task, backup3Time, baseId + 4, 
          AndroidScheduleMode.inexactAllowWhileIdle,
          isMain: false,
          titlePrefix: '🚨 URGENT OVERDUE: '
        );
        scheduledCount++;
      }
      
      print('TaskNotificationService: Scheduled $scheduledCount notification strategies for maximum reliability');
    } catch (e) {
      print('TaskNotificationService: Error scheduling reliable notifications: $e');
    }
  }

  /// Schedule a single notification with a specific strategy
  Future<void> _scheduleNotificationWithStrategy(
    Task task, 
    tz.TZDateTime scheduledDate, 
    int notificationId,
    AndroidScheduleMode scheduleMode,
    {bool isMain = true, String titlePrefix = '', bool isPreNotification = false, bool isCritical = false}
  ) async {
    // Configure Android notification details with high priority settings
    final AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'task_deadline_channel',
      'Task Deadlines',
      channelDescription: 'Critical task deadline notifications',
      importance: isCritical ? Importance.max : Importance.high,
      priority: isCritical ? Priority.max : Priority.high,
      icon: '@mipmap/ic_launcher',
      color: isCritical ? const Color(0xFFFF5722) : const Color(0xFF4CAF50),
      colorized: true,
      ongoing: false,
      autoCancel: !isCritical, // Critical notifications stay until dismissed
      playSound: true,
      enableVibration: true,
      category: isCritical ? AndroidNotificationCategory.alarm : AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      ticker: isPreNotification ? 'Task Due Soon: ${task.title}' : 'Task Due: ${task.title}',
      usesChronometer: false,
      showWhen: true,
      fullScreenIntent: isMain || isCritical, // Full screen for main and critical notifications
      // Custom vibration pattern for different notification types
      vibrationPattern: isCritical 
          ? Int64List.fromList([0, 1000, 500, 1000, 500, 1000]) // Long pattern for critical
          : isPreNotification 
              ? Int64List.fromList([0, 300, 100, 300]) // Short pattern for pre-notification
              : Int64List.fromList([0, 500, 250, 500]), // Normal pattern
      // Add action buttons only for main notification
      actions: isMain ? <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'mark_complete',
          'Complete',
          icon: DrawableResourceAndroidBitmap('@drawable/ic_check'),
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'snooze_5min',
          'Snooze 5min',
          showsUserInterface: false,
        ),
      ] : null,
    );

    // Configure iOS notification details
    final DarwinNotificationDetails iosNotificationDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: isCritical ? 'alarm.aiff' : 'default',
      badgeNumber: 1,
      threadIdentifier: 'task_notifications',
      categoryIdentifier: 'TASK_DEADLINE_CATEGORY',
      interruptionLevel: isCritical 
          ? InterruptionLevel.critical 
          : isPreNotification 
              ? InterruptionLevel.active 
              : InterruptionLevel.timeSensitive,
      subtitle: isPreNotification ? 'Due Soon' : 'Due Now',
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    // Create notification title and body
    final String title = isPreNotification 
        ? '${titlePrefix}Task Due in 30 seconds: ${task.title}'
        : '${titlePrefix}Task Due: ${task.title}';
    final String body = _createEnhancedNotificationBody(task, isMain, isPreNotification, isCritical);

    // Schedule the notification
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: scheduleMode,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'task_due:${task.id}:${isMain ? 'main' : 'backup'}',
    );

    print('TaskNotificationService: Scheduled ${scheduleMode.toString().split('.').last} notification (ID: $notificationId) for: ${scheduledDate}');
  }

  /// Create enhanced notification body with more details
  String _createEnhancedNotificationBody(Task task, bool isMain, [bool isPreNotification = false, bool isCritical = false]) {
    final StringBuffer body = StringBuffer();
    
    // Add special message for pre-notifications
    if (isPreNotification) {
      body.writeln('⏰ This task is due in 30 seconds!');
      body.writeln('');
    }
    
    // Add critical warning for overdue tasks
    if (isCritical) {
      body.writeln('🚨 CRITICAL: This task is now overdue!');
      body.writeln('');
    }
    
    // Add task description if available
    if (task.description != null && task.description!.isNotEmpty) {
      body.writeln(task.description!);
    }
    
    // Add priority indicator with emoji
    final String priorityText = _getPriorityText(task.priority);
    body.writeln('Priority: $priorityText');
    
    // Add due time
    final String dueTime = '${task.dueDate.hour.toString().padLeft(2, '0')}:${task.dueDate.minute.toString().padLeft(2, '0')}';
    body.writeln('Due: $dueTime');
    
    // Add category if available
    if (task.category.isNotEmpty && task.category != 'other') {
      body.writeln('Category: ${task.category}');
    }
    
    // Add time-specific advice
    if (isPreNotification) {
      body.writeln('\n🏃‍♂️ Final chance to complete this task!');
    } else if (isCritical) {
      body.writeln('\n⚠️ Please complete this task immediately!');
    } else if (isMain) {
      body.writeln('\n💡 Tap to open app or use action buttons');
    }
    
    return body.toString().trim();
  }



  /// Get priority text with emoji
  String _getPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
        return '🚨 Urgent';
      case TaskPriority.high:
        return '⚠️ High';
      case TaskPriority.medium:
        return '📋 Medium';
      case TaskPriority.low:
        return '📝 Low';
    }
  }

  /// Generate a unique notification ID from task ID (public method)
  int generateNotificationId(String taskId) {
    return _generateNotificationId(taskId);
  }

  /// Generate a unique notification ID from task ID
  int _generateNotificationId(String taskId) {
    // Create a hash from the task ID
    int hash = 0;
    for (int i = 0; i < taskId.length; i++) {
      hash = ((hash << 5) - hash) + taskId.codeUnitAt(i);
      hash = hash & hash; // Convert to 32-bit integer
    }
    return hash.abs() % 2147483647; // Ensure positive and within int range
  }

  /// Verify that a notification was successfully scheduled
  Future<void> _verifyNotificationScheduled(int notificationId, String taskTitle) async {
    try {
      final List<PendingNotificationRequest> pendingNotifications = 
          await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      
      final bool isScheduled = pendingNotifications.any((notification) => 
          notification.id == notificationId);
      
      if (isScheduled) {
        print('TaskNotificationService: ✓ Verified notification scheduled for: $taskTitle');
      } else {
        print('TaskNotificationService: ⚠️ Warning: Notification not found in pending list for: $taskTitle');
      }
    } catch (e) {
      print('TaskNotificationService: Error verifying notification: $e');
    }
  }

  /// Cancel a task notification and all its backups
  Future<void> cancelTaskNotification(String taskId) async {
    // Disabled for demo release
    return;
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    // Disabled for demo release
    return;
  }

  /// Get count of pending notifications
  Future<int> getPendingNotificationCount() async {
    return 0;
  }

  /// Get all pending notifications for debugging
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return [];
  }

  /// Check if device has proper permissions for exact alarms
  Future<bool> checkExactAlarmPermission() async {
    return true;
  }

  /// Show a detailed system notification test
  Future<void> performSystemNotificationTest() async {
    // Disabled for demo release
    return;
  }

  /// Show immediate notification (for testing)
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;
    
    try {
      const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
        'task_deadline_channel',
        'Task Deadlines',
        channelDescription: 'Notifications for task due dates and deadlines',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF4CAF50),
        colorized: true,
        playSound: true,
        enableVibration: true,
      );

      const DarwinNotificationDetails iosNotificationDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      
      print('TaskNotificationService: Immediate notification sent: $title');
    } catch (e) {
      print('TaskNotificationService: Error showing immediate notification: $e');
    }
  }

  /// Test notification scheduling by creating multiple notifications for maximum reliability
  Future<void> testNotificationScheduling() async {
    if (kIsWeb) return;
    
    try {
      print('TaskNotificationService: Starting enhanced test notification scheduling...');
      
      final testTime = DateTime.now().add(const Duration(seconds: 10));
      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(testTime, tz.local);
      
      // Schedule multiple test notifications with different strategies
      const int testBaseId = 999000;
      
      // Test 1: exactAllowWhileIdle
      await _scheduleTestNotification(
        scheduledDate, 
        testBaseId, 
        AndroidScheduleMode.exactAllowWhileIdle,
        '🧪 Test 1: ExactAllowWhileIdle'
      );
      
      // Test 2: exact (3 seconds later)
      await _scheduleTestNotification(
        scheduledDate.add(const Duration(seconds: 3)), 
        testBaseId + 1, 
        AndroidScheduleMode.exact,
        '🧪 Test 2: Exact (+3s)'
      );
      
      // Test 3: inexactAllowWhileIdle (6 seconds later)
      await _scheduleTestNotification(
        scheduledDate.add(const Duration(seconds: 6)), 
        testBaseId + 2, 
        AndroidScheduleMode.inexactAllowWhileIdle,
        '🧪 Test 3: InexactAllowWhileIdle (+6s)'
      );
      
      // Test 4: Another exactAllowWhileIdle (9 seconds later)
      await _scheduleTestNotification(
        scheduledDate.add(const Duration(seconds: 9)), 
        testBaseId + 3, 
        AndroidScheduleMode.exactAllowWhileIdle,
        '🧪 Test 4: ExactAllowWhileIdle (+9s)'
      );
      
      print('TaskNotificationService: Enhanced test notifications scheduled:');
      print('  - 10s: ExactAllowWhileIdle');
      print('  - 13s: Exact');
      print('  - 16s: InexactAllowWhileIdle');
      print('  - 19s: ExactAllowWhileIdle');
      print('  Put app in background and wait...');
      
    } catch (e) {
      print('TaskNotificationService: Error scheduling enhanced test notifications: $e');
    }
  }

  /// Reschedule all notifications after system boot or app update
  Future<void> rescheduleNotificationsAfterBoot() async {
    if (kIsWeb) return;
    
    try {
      print('TaskNotificationService: Rescheduling notifications after boot...');
      
      // Clear any existing notifications first
      await cancelAllNotifications();
      
      // This would typically be called by the TaskNotificationIntegration
      // to reschedule all active task notifications
      print('TaskNotificationService: Boot rescheduling complete. TaskNotificationIntegration should handle task rescheduling.');
      
    } catch (e) {
      print('TaskNotificationService: Error rescheduling notifications after boot: $e');
    }
  }

  /// Check system notification settings and provide feedback
  Future<Map<String, dynamic>> getSystemNotificationStatus() async {
    if (kIsWeb) return {'platform': 'web', 'supported': false};
    
    try {
      final Map<String, dynamic> status = {
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'supported': false,
        'initialized': false,
      };
      
      // Check permissions
      // Disabled in demo
      
      if (Platform.isAndroid) {
        // Disabled in demo
      }
      
      // Check pending notifications
      final pendingNotifications = await getPendingNotifications();
      status['pendingNotificationsCount'] = pendingNotifications.length;
      
      // Check timezone
      status['timezone'] = tz.local.name;
      
      print('TaskNotificationService: System status: $status');
      return status;
      
    } catch (e) {
      print('TaskNotificationService: Error getting system status: $e');
      return {'error': e.toString()};
    }
  }

  /// Schedule a single test notification with specific strategy
  Future<void> _scheduleTestNotification(
    tz.TZDateTime scheduledDate,
    int notificationId,
    AndroidScheduleMode scheduleMode,
    String title,
  ) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_deadline_channel',
      'Task Deadlines',
      channelDescription: 'Test notification with different scheduling strategies',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF2196F3),
      colorized: true,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      showWhen: true,
      fullScreenIntent: true, // Try to show as full screen
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      title,
      'Strategy: ${scheduleMode.toString().split('.').last}\nScheduled: ${scheduledDate.toString()}\nCurrent: ${DateTime.now()}',
      scheduledDate,
      notificationDetails,
      androidScheduleMode: scheduleMode,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'enhanced_test_notification:$notificationId',
    );
  }
}
