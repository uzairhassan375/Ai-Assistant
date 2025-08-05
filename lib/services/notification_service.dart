import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/material.dart';
import 'package:aiassistant1/models/task.dart';
import 'package:aiassistant1/services/android_notification_helper.dart';
import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  // Global key for navigation context
  static GlobalKey<NavigatorState>? navigatorKey;
  
  // Callback for in-app notification handling
  static Function(Task)? onInAppNotification;

  // Helper method to check if running on Android (not web)
  bool get _isAndroid {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid;
    } catch (e) {
      return false;
    }
  }

  Future<void> init() async {
    // For web, skip all native notification initialization
    if (kIsWeb) {
      print('Web platform detected - local notifications not supported');
      return;
    }
    
    // Only initialize timezone and Android-specific features on mobile platforms
    tz.initializeTimeZones();
    
    // Clear any corrupted notification data on Android to prevent TypeToken issues  
    if (Platform.isAndroid) {
      await AndroidNotificationHelper.clearCorruptedNotifications();
    }
    
    // Initialize notification channels
    await _initializeNotificationChannels();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );
    
    try {
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );
    } catch (e) {
      // If initialization fails due to TypeToken issues on Android, try to recover
      if (_isAndroid && e.toString().contains('TypeToken')) {
        await AndroidNotificationHelper.clearCorruptedNotifications();
        // Retry initialization
        await flutterLocalNotificationsPlugin.initialize(
          initializationSettings,
          onDidReceiveNotificationResponse: _onNotificationTap,
        );
      } else {
        rethrow;
      }
    }

    // Request notification permission
    await _requestNotificationPermission();
  }

  // Handle notification tap
  void _onNotificationTap(NotificationResponse notificationResponse) {
    final payload = notificationResponse.payload;
    if (payload != null && navigatorKey?.currentContext != null) {
      // Handle notification tap - you can navigate to task details or show dialog
      _showInAppReminderDialog(navigatorKey!.currentContext!, payload);
    }
  }

  Future<void> _requestNotificationPermission() async {
    // Skip permission requests on web
    if (kIsWeb) {
      return;
    }
    
    final status = await Permission.notification.status;
    if (status.isDenied) {
      await Permission.notification.request();
    }
    
    // Check Android-specific permissions
    if (_isAndroid) {
      await _checkBatteryOptimization();
      await _checkExactAlarmPermission();
    }
  }
  
  Future<void> _checkExactAlarmPermission() async {
    try {
      final status = await Permission.scheduleExactAlarm.status;
      if (status.isDenied) {
        print('Exact alarm permission denied - this may prevent scheduled notifications!');
        print('Consider requesting exact alarm permission for better notification delivery.');
      }
    } catch (e) {
      print('Error checking exact alarm permission: $e');
    }
  }
  
  Future<void> _checkBatteryOptimization() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (status.isDenied) {
        print('Battery optimization is enabled - this may prevent notifications from firing!');
        print('Consider requesting battery optimization exemption for better notification delivery.');
        print('MIUI/Xiaomi users need additional settings: Autostart, Battery saver, Background limits, MIUI optimization, Lock screen cleanup');
        
        // Optionally request permission (this will open settings)
        // await Permission.ignoreBatteryOptimizations.request();
      } else {
        print('Battery optimization status: $status');
      }
    } catch (e) {
      print('Could not check battery optimization status: $e');
    }
  }

  Future<void> scheduleReminderNotification({
    required int id,
    required String title,
    required String body,
    required DateTime dueDate,
    String? taskId,
  }) async {
    // Skip scheduling on web platform
    if (kIsWeb) {
      print('Web platform: Notification scheduling not supported - $title');
      return;
    }
    
    await _scheduleReminderNotificationNative(
      id: id,
      title: title,
      body: body,
      dueDate: dueDate,
      taskId: taskId,
    );
  }

  Future<void> _scheduleReminderNotificationNative({
    required int id,
    required String title,
    required String body,
    required DateTime dueDate,
    String? taskId,
  }) async {
    try {
      // Check if the due date is in the future
      if (dueDate.isBefore(DateTime.now())) {
        print('Cannot schedule notification for past date: $dueDate');
        return;
      }
      
      // Ensure notification permissions
      await _requestNotificationPermission();
      
      // Request exact alarm permission for Android
      if (_isAndroid) {
        final status = await Permission.scheduleExactAlarm.status;
        if (status.isDenied) {
          final result = await Permission.scheduleExactAlarm.request();
          if (result.isDenied || result.isPermanentlyDenied) {
            print('Exact alarm permission denied for reminder notification');
            return;
          }
        }
      }
      
      final scheduledDate = tz.TZDateTime.from(dueDate, tz.local);
      
      // Debug information
      print('Scheduling reminder notification:');
      print('  ID: $id');
      print('  Title: $title');
      print('  Body: $body');
      print('  Scheduled for: $scheduledDate');
      print('  Current time: ${tz.TZDateTime.now(tz.local)}');
      print('  Task ID: $taskId');
      
      // Create payload with task information
      final payload = taskId ?? id.toString();
      
      // Cancel any existing notification with this ID first
      await flutterLocalNotificationsPlugin.cancel(id);
      
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        '🔔 Task Reminder',
        body,
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'reminder_channel',
            'Task Reminders',
            channelDescription: 'Notifications for task due dates and reminders',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
            icon: '@mipmap/ic_launcher',
            color: Colors.blue,
            ledColor: Colors.blue,
            ledOnMs: 1000,
            ledOffMs: 500,
            autoCancel: true,
            ongoing: false,
            enableLights: true,
            ticker: 'Task reminder notification',
            // MIUI-specific settings for better compatibility
            category: AndroidNotificationCategory.reminder,
            visibility: NotificationVisibility.public,
            timeoutAfter: null, // Don't auto-dismiss
            channelShowBadge: true,
            fullScreenIntent: false,
            when: scheduledDate.millisecondsSinceEpoch,
            usesChronometer: false,
            chronometerCountDown: false,
            showProgress: false,
            groupKey: 'task_reminders',
            setAsGroupSummary: false,
            groupAlertBehavior: GroupAlertBehavior.all,
            largeIcon: null,
            styleInformation: null,
            audioAttributesUsage: AudioAttributesUsage.alarm,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
            badgeNumber: 1,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
        matchDateTimeComponents: null,
      );
      
      print('Reminder notification scheduled successfully');
      
    } catch (e) {
      print('Error scheduling reminder notification: $e');
      // Handle TypeToken errors on Android
      if (Platform.isAndroid && e.toString().contains('TypeToken')) {
        // Clear corrupted data and retry
        await AndroidNotificationHelper.clearCorruptedNotifications();
        
        // Retry the scheduling
        await _retryScheduleNotification(id, title, body, dueDate, taskId);
      } else {
        rethrow;
      }
    }
  }

  // Retry method for scheduling notifications after clearing corrupted data
  Future<void> _retryScheduleNotification(
    int id,
    String title,
    String body,
    DateTime dueDate,
    String? taskId,
  ) async {
    print('Retrying notification scheduling after clearing corrupted data');
    
    final scheduledDate = tz.TZDateTime.from(dueDate, tz.local);
    final payload = taskId ?? id.toString();
    
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      '🔔 Task Reminder',
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Task Reminders',
          channelDescription: 'Notifications for task due dates and reminders',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
          icon: '@mipmap/ic_launcher',
          color: Colors.blue,
          ledColor: Colors.blue,
          ledOnMs: 1000,
          ledOffMs: 500,
          autoCancel: true,
          ongoing: false,
          enableLights: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
          badgeNumber: 1,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
      matchDateTimeComponents: null,
    );
    
    print('Retry notification scheduling completed');
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  // Show in-app reminder dialog
  void _showInAppReminderDialog(BuildContext context, String taskInfo) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Task Reminder',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your task is due now!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Task: $taskInfo',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Dismiss',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // You can add navigation to task details here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'View Task',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Schedule immediate in-app notification for testing
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // For web, show browser notification or in-app message
    if (kIsWeb) {
      print('Web notification: $title - $body');
      // You could implement web notifications here if needed
      return;
    }
    
    try {
      // Ensure notification permission is granted
      await _requestNotificationPermission();
      
      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        '🔔 $title',
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'immediate_channel',
            'Immediate Notifications',
            channelDescription: 'Immediate task notifications',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
            icon: '@mipmap/ic_launcher',
            color: Colors.blue,
            ticker: 'Immediate notification',
            autoCancel: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      // If immediate notification fails, at least show an in-app dialog
      if (navigatorKey?.currentContext != null) {
        _showInAppReminderDialog(navigatorKey!.currentContext!, body);
      }
      rethrow;
    }
  }

  // Schedule a notification for 5 seconds from now (for testing)
  Future<void> scheduleTestNotification({
    required String title,
    required String body,
  }) async {
    try {
      // First, request notification permissions
      await _requestNotificationPermission();
      
      // Request exact alarm permission for Android
      if (Platform.isAndroid) {
        final status = await Permission.scheduleExactAlarm.status;
        if (status.isDenied) {
          final result = await Permission.scheduleExactAlarm.request();
          if (result.isDenied || result.isPermanentlyDenied) {
            // If permission denied, fall back to immediate notification
            await showImmediateNotification(
              title: 'Permission Test',
              body: 'Exact alarm permission denied, showing immediate notification instead.',
              payload: 'Permission denied fallback',
            );
            return;
          }
        }
      }
      
      // Cancel any existing test notifications first
      await flutterLocalNotificationsPlugin.cancel(999);
      await flutterLocalNotificationsPlugin.cancel(998); // Cancel backup notification too
      
      // Schedule for 5 seconds from now
      final scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));
      
      // Debug: Print the scheduled time
      print('Scheduling test notification for: $scheduledDate');
      print('Current time: ${tz.TZDateTime.now(tz.local)}');
      
      // Schedule the main test notification
      await flutterLocalNotificationsPlugin.zonedSchedule(
        999, // Test ID
        '🧪 Test Reminder',
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Test notifications for debugging',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
            icon: '@mipmap/ic_launcher',
            color: Colors.blue,
            ticker: 'Test notification ticker',
            autoCancel: true,
            ongoing: false,
            enableLights: true,
            ledColor: Colors.blue,
            ledOnMs: 1000,
            ledOffMs: 500,
            fullScreenIntent: true, // Make it more prominent
            category: AndroidNotificationCategory.alarm,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
            badgeNumber: 1,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'Test notification payload',
        matchDateTimeComponents: null,
      );
      
      // Schedule a backup notification 1 second later in case the first one fails
      final backupDate = scheduledDate.add(const Duration(seconds: 1));
      await flutterLocalNotificationsPlugin.zonedSchedule(
        998, // Backup Test ID
        '🔔 Backup Test',
        'Backup test notification (in case first one failed)',
        backupDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Test notifications for debugging',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
            icon: '@mipmap/ic_launcher',
            color: Colors.orange,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'Backup test notification',
      );
      
      print('Test notification scheduled successfully');
      print('Backup notification also scheduled for: $backupDate');
      
      // Don't show immediate confirmation to avoid confusion
      // The user should only see the scheduled notifications after 5-6 seconds
      
    } catch (e) {
      print('Error scheduling test notification: $e');
      // If scheduling fails, try immediate notification as fallback
      await showImmediateNotification(
        title: 'Test Notification (Immediate)',
        body: 'Scheduled test failed: $e. Showing immediate notification instead.',
        payload: 'Fallback test notification',
      );
      rethrow;
    }
  }

  // Get the count of scheduled notifications for debugging
  Future<int> getScheduledNotificationCount() async {
    try {
      final pendingNotifications = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
      print('Pending notifications count: ${pendingNotifications.length}');
      
      for (var notification in pendingNotifications) {
        print('Notification ID: ${notification.id}, Title: ${notification.title}, Body: ${notification.body}');
      }
      
      return pendingNotifications.length;
    } catch (e) {
      print('Error getting notification count: $e');
      
      if (Platform.isAndroid) {
        try {
          return await AndroidNotificationHelper.getScheduledNotificationCount();
        } catch (androidError) {
          print('Android helper also failed: $androidError');
          return 0;
        }
      }
      return 0;
    }
  }

  // Clear all scheduled notifications (useful for debugging TypeToken issues)
  Future<void> clearAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    if (Platform.isAndroid) {
      await AndroidNotificationHelper.clearCorruptedNotifications();
    }
  }

  // Schedule task deadline notification
  Future<void> scheduleTaskDeadlineNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String taskId,
  }) async {
    // Skip scheduling on web platform
    if (kIsWeb) {
      print('Web platform: Task deadline notification scheduling not supported - $title');
      return;
    }
    
    try {
      // Check if the scheduled date is in the future
      if (scheduledDate.isBefore(DateTime.now())) {
        print('Cannot schedule task deadline notification for past date: $scheduledDate');
        return;
      }
      
      // Ensure notification permissions
      await _requestNotificationPermission();
      
      // Request exact alarm permission for Android
      if (_isAndroid) {
        final status = await Permission.scheduleExactAlarm.status;
        if (status.isDenied) {
          final result = await Permission.scheduleExactAlarm.request();
          if (result.isDenied || result.isPermanentlyDenied) {
            print('Exact alarm permission denied for task deadline notification');
            return;
          }
        }
      }
      
      final scheduledTZDate = tz.TZDateTime.from(scheduledDate, tz.local);
      
      // Debug information
      print('Scheduling task deadline notification:');
      print('  ID: $id');
      print('  Title: $title');
      print('  Task ID: $taskId');
      print('  Current time: ${DateTime.now()}');
      print('  Scheduled time: $scheduledDate');
      print('  TZ Scheduled time: $scheduledTZDate');
      
      final AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
        'task_deadline_channel',
        'Task Deadline Notifications',
        channelDescription: 'Notifications for task deadlines and due dates',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF4CAF50), // Green color for deadline alerts
        colorized: true,
        ongoing: false,
        autoCancel: true,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 500, 500]),
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        ticker: 'Task Deadline Alert',
        when: null,
        usesChronometer: false,
        chronometerCountDown: false,
      );

      const DarwinNotificationDetails iosNotificationDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        badgeNumber: 1,
        threadIdentifier: 'task_deadline_thread',
        categoryIdentifier: 'TASK_DEADLINE_CATEGORY',
        interruptionLevel: InterruptionLevel.active,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id, // Unique notification ID
        title,
        body,
        scheduledTZDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'task_deadline:$taskId',
      );
      
      print('Task deadline notification scheduled successfully');
      
      // Verify the notification was scheduled
      final pendingNotifications = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
      final ourNotification = pendingNotifications.where((n) => n.id == id).toList();
      if (ourNotification.isNotEmpty) {
        print('Verification: Task deadline notification found in pending list');
      } else {
        print('Warning: Task deadline notification not found in pending list');
      }
      
    } catch (e) {
      print('Error scheduling task deadline notification: $e');
      rethrow;
    }
  }

  /// Initialize notification channels for better organization and reliability
  Future<void> _initializeNotificationChannels() async {
    if (kIsWeb || !_isAndroid) return;
    
    try {
      // High importance channel for task deadlines
      const AndroidNotificationChannel taskDeadlineChannel = AndroidNotificationChannel(
        'task_deadline_channel',
        'Task Deadline Notifications',
        description: 'Notifications for task deadlines and due dates',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );
      
      // Medium importance channel for reminders
      const AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
        'reminder_channel',
        'Task Reminders',
        description: 'General task reminder notifications',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );
      
      // Low importance channel for overdue tasks
      const AndroidNotificationChannel overdueChannel = AndroidNotificationChannel(
        'overdue_channel',
        'Overdue Tasks',
        description: 'Notifications for overdue tasks',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );
      
      // Create the channels
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(taskDeadlineChannel);
          
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(reminderChannel);
          
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(overdueChannel);
      
      print('NotificationService: Initialized notification channels');
    } catch (e) {
      print('NotificationService: Error initializing channels: $e');
    }
  }
}
