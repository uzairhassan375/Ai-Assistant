import 'package:aiassistant1/models/task.dart';
import 'package:aiassistant1/services/task_notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class TaskNotificationIntegration {
  static final TaskNotificationIntegration _instance = TaskNotificationIntegration._internal();
  factory TaskNotificationIntegration() => _instance;
  TaskNotificationIntegration._internal();

  final TaskNotificationService _notificationService = TaskNotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  StreamSubscription<QuerySnapshot>? _taskStreamSubscription;
  Timer? _overdueCheckTimer;

  /// Initialize automatic task notification scheduling
  Future<void> initialize() async {
    print('TaskNotificationIntegration: Initializing...');
    
    // Ensure notification service is initialized
    await _notificationService.initialize();
    
    // Check system notification status
    final status = await _notificationService.getSystemNotificationStatus();
    print('TaskNotificationIntegration: System status: $status');
    
    // Start listening to task changes
    await _startTaskListener();
    
    // Start periodic check for overdue tasks
    _startOverdueTaskChecker();
    
    // Reschedule any notifications that might have been lost due to system restart
    await _rescheduleExistingTasks();
    
    print('TaskNotificationIntegration: Initialized successfully');
  }

  /// Reschedule notifications for all existing tasks (e.g., after boot)
  Future<void> _rescheduleExistingTasks() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      print('TaskNotificationIntegration: Rescheduling existing tasks...');
      
      // Get all incomplete tasks with reminders
      final tasksQuery = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: currentUser.uid)
          .where('isCompleted', isEqualTo: false)
          .where('isArchived', isEqualTo: false)
          .where('isReminder', isEqualTo: true)
          .get();

      int rescheduledCount = 0;
      final now = DateTime.now();
      
      for (final doc in tasksQuery.docs) {
        final task = Task.fromMap(doc.id, doc.data());
        
        // Only reschedule future tasks
        if (task.dueDate.isAfter(now.add(const Duration(minutes: 1)))) {
          await _notificationService.scheduleTaskNotification(task);
          rescheduledCount++;
        }
      }
      
      print('TaskNotificationIntegration: Rescheduled $rescheduledCount tasks');
    } catch (e) {
      print('TaskNotificationIntegration: Error rescheduling existing tasks: $e');
    }
  }

  /// Start periodic checker for overdue tasks (every 5 minutes)
  void _startOverdueTaskChecker() {
    _overdueCheckTimer?.cancel();
    _overdueCheckTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkForOverdueTasks();
    });
    
    // Also run immediately
    _checkForOverdueTasks();
  }

  /// Check for overdue tasks and send immediate notifications
  Future<void> _checkForOverdueTasks() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final now = DateTime.now();
      final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));
      
      // Query for tasks that are overdue within the last 5 minutes
      final overdueTasksQuery = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: currentUser.uid)
          .where('isCompleted', isEqualTo: false)
          .where('isArchived', isEqualTo: false)
          .where('isReminder', isEqualTo: true)
          .where('dueDate', isGreaterThan: Timestamp.fromDate(fiveMinutesAgo))
          .where('dueDate', isLessThan: Timestamp.fromDate(now))
          .get();

      print('TaskNotificationIntegration: Found ${overdueTasksQuery.docs.length} recently overdue tasks');

      for (final doc in overdueTasksQuery.docs) {
        final task = Task.fromMap(doc.id, doc.data());
        await _notificationService.showImmediateNotification(
          title: '🚨 Task Overdue: ${task.title}',
          body: 'This task was due at ${task.dueDate.hour.toString().padLeft(2, '0')}:${task.dueDate.minute.toString().padLeft(2, '0')}. Please complete it soon!',
          payload: 'task_overdue:${task.id}',
        );
      }
    } catch (e) {
      print('TaskNotificationIntegration: Error checking overdue tasks: $e');
    }
  }

  /// Start listening to task changes for automatic notification scheduling
  Future<void> _startTaskListener() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('TaskNotificationIntegration: No authenticated user');
      return;
    }

    print('TaskNotificationIntegration: Starting task listener for user: ${currentUser.uid}');
    
    // Cancel existing subscription
    await _taskStreamSubscription?.cancel();
    
    // Listen to all tasks for the current user
    _taskStreamSubscription = _firestore
        .collection('tasks')
        .where('userId', isEqualTo: currentUser.uid)
        .snapshots()
        .listen(
          _handleTaskChanges,
          onError: (error) {
            print('TaskNotificationIntegration: Error listening to tasks: $error');
          },
        );
  }

  /// Handle task document changes
  Future<void> _handleTaskChanges(QuerySnapshot snapshot) async {
    print('TaskNotificationIntegration: Processing ${snapshot.docs.length} tasks');
    
    for (DocumentChange change in snapshot.docChanges) {
      final taskData = change.doc.data() as Map<String, dynamic>;
      final task = Task.fromMap(change.doc.id, taskData);
      
      switch (change.type) {
        case DocumentChangeType.added:
        case DocumentChangeType.modified:
          await _handleTaskAddedOrModified(task);
          break;
        case DocumentChangeType.removed:
          await _handleTaskRemoved(task);
          break;
      }
    }
  }

  /// Handle task added or modified
  Future<void> _handleTaskAddedOrModified(Task task) async {
    try {
      // Always cancel existing notification first to avoid duplicates
      if (task.id != null) {
        await _notificationService.cancelTaskNotification(task.id!);
      }

      // Skip if task is completed, archived, or doesn't have reminders enabled
      if (task.isCompleted || task.isArchived || !task.isReminder) {
        print('TaskNotificationIntegration: Skipping notification for task ${task.id} (completed/archived/no reminder)');
        return;
      }

      // Skip if due date is too close or in the past (30 second buffer for scheduling)
      final now = DateTime.now();
      if (task.dueDate.isBefore(now.add(const Duration(seconds: 30)))) {
        print('TaskNotificationIntegration: Task due date is too close or in the past: ${task.title}');
        
        // Show immediate notification for recently overdue tasks (within last hour)
        if (task.dueDate.isBefore(now) && task.dueDate.isAfter(now.subtract(const Duration(hours: 1)))) {
          await _notificationService.showImmediateNotification(
            title: '⏰ Overdue Task: ${task.title}',
            body: 'This task was due at ${task.dueDate.hour.toString().padLeft(2, '0')}:${task.dueDate.minute.toString().padLeft(2, '0')}. Please complete it now!',
            payload: 'task_overdue:${task.id}',
          );
        }
        return;
      }

      print('TaskNotificationIntegration: Scheduling notification for task: ${task.title}');
      print('  - Due date: ${task.dueDate}');
      print('  - Current time: $now');
      print('  - Time until due: ${task.dueDate.difference(now).inMinutes} minutes');
      
      // Schedule the notification with enhanced reliability
      await _notificationService.scheduleTaskNotification(task);
      
      // Verify the notification was scheduled
      await _verifyNotificationScheduled(task);
      
      // Double-check that we have proper permissions
      final systemStatus = await _notificationService.getSystemNotificationStatus();
      if (systemStatus['exactAlarmPermission']?.toString().contains('denied') == true) {
        print('TaskNotificationIntegration: ⚠️ WARNING: Exact alarm permission denied for task: ${task.title}');
      }
      
      print('TaskNotificationIntegration: ✓ Successfully scheduled notification for: ${task.title}');
    } catch (e) {
      print('TaskNotificationIntegration: Error handling task ${task.id}: $e');
      
      // Try once more with a fallback strategy
      try {
        await Future.delayed(const Duration(seconds: 2));
        await _notificationService.scheduleTaskNotification(task);
        print('TaskNotificationIntegration: ✓ Retry successful for: ${task.title}');
      } catch (retryError) {
        print('TaskNotificationIntegration: ❌ Retry failed for ${task.title}: $retryError');
      }
    }
  }

  /// Verify that a notification was properly scheduled
  Future<void> _verifyNotificationScheduled(Task task) async {
    try {
      final pendingNotifications = await _notificationService.getPendingNotifications();
      final taskNotificationId = _notificationService.generateNotificationId(task.id!);
      
      final isScheduled = pendingNotifications.any((notification) => 
          notification.id == taskNotificationId);
      
      if (isScheduled) {
        print('TaskNotificationIntegration: ✓ Verified notification scheduled for: ${task.title}');
      } else {
        print('TaskNotificationIntegration: ⚠️ Warning: Notification not found in pending list for: ${task.title}');
        print('  - Expected notification ID: $taskNotificationId');
        print('  - Total pending notifications: ${pendingNotifications.length}');
      }
    } catch (e) {
      print('TaskNotificationIntegration: Error verifying notification: $e');
    }
  }

  /// Handle task removed
  Future<void> _handleTaskRemoved(Task task) async {
    try {
      if (task.id != null) {
        await _notificationService.cancelTaskNotification(task.id!);
        print('TaskNotificationIntegration: Cancelled notification for removed task: ${task.title}');
      }
    } catch (e) {
      print('TaskNotificationIntegration: Error cancelling notification for removed task: $e');
    }
  }

  /// Manually schedule notification for a specific task
  Future<void> scheduleTaskNotification(Task task) async {
    await _handleTaskAddedOrModified(task);
  }

  /// Cancel notification for a specific task
  Future<void> cancelTaskNotification(String taskId) async {
    await _notificationService.cancelTaskNotification(taskId);
  }

  /// Get pending notification count
  Future<int> getPendingNotificationCount() async {
    return await _notificationService.getPendingNotificationCount();
  }

  /// Reinitialize after authentication changes
  Future<void> reinitialize() async {
    print('TaskNotificationIntegration: Reinitializing after auth change...');
    await dispose();
    await initialize();
  }

  /// Clean up resources
  Future<void> dispose() async {
    print('TaskNotificationIntegration: Disposing...');
    await _taskStreamSubscription?.cancel();
    _taskStreamSubscription = null;
    _overdueCheckTimer?.cancel();
    _overdueCheckTimer = null;
  }
}
