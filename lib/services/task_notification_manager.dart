import 'package:aiassistant1/models/task.dart';
import 'package:aiassistant1/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class TaskNotificationManager {
  static final TaskNotificationManager _instance = TaskNotificationManager._internal();
  factory TaskNotificationManager() => _instance;
  TaskNotificationManager._internal();

  final NotificationService _notificationService = NotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final FirebaseAuth _auth = FirebaseAuth.instance;
  
  StreamSubscription<QuerySnapshot>? _taskStreamSubscription;
  Timer? _deadlineCheckTimer;
  Timer? _realTimeChecker; // New real-time checker for immediate notifications

  /// Initialize the task notification manager
  /// This sets up listeners for task changes and periodic deadline checks
  Future<void> initialize() async {
    print('TaskNotificationManager: Initializing...');
    
    // Start listening to task changes for the current user
    await _startTaskListener();
    
    // Start periodic deadline checking
    _startDeadlineChecker();
    
    // Start real-time checker (every 1 minute for precise timing)
    _startRealTimeChecker();
    
    print('TaskNotificationManager: Initialized successfully');
  }

  /// Start listening to task changes for automatic notification scheduling
  Future<void> _startTaskListener() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('TaskNotificationManager: No authenticated user, skipping task listener');
      return;
    }

    print('TaskNotificationManager: Starting task listener for user: ${currentUser.uid}');
    
    // Cancel existing subscription if any
    await _taskStreamSubscription?.cancel();
    
    // Listen to task changes
    _taskStreamSubscription = _firestore
        .collection('tasks')
        .where('userId', isEqualTo: currentUser.uid)
        .where('isCompleted', isEqualTo: false)
        .where('isArchived', isEqualTo: false)
        .snapshots()
        .listen(
          _handleTaskChanges,
          onError: (error) {
            print('TaskNotificationManager: Error listening to tasks: $error');
          },
        );
  }

  /// Handle task document changes
  Future<void> _handleTaskChanges(QuerySnapshot snapshot) async {
    print('TaskNotificationManager: Processing ${snapshot.docs.length} active tasks');
    
    for (DocumentChange change in snapshot.docChanges) {
      final taskData = change.doc.data() as Map<String, dynamic>;
      final task = Task.fromMap(change.doc.id, taskData);
      
      switch (change.type) {
        case DocumentChangeType.added:
        case DocumentChangeType.modified:
          await _scheduleTaskNotifications(task);
          break;
        case DocumentChangeType.removed:
          await _cancelTaskNotifications(task);
          break;
      }
    }
  }

  /// Schedule notifications for a task based on its deadline
  Future<void> _scheduleTaskNotifications(Task task) async {
    try {
      // Skip if no reminder is set or task is completed/archived
      if (!task.isReminder || task.isCompleted || task.isArchived) {
        print('TaskNotificationManager: Skipping notification for task ${task.id} (no reminder or completed/archived)');
        return;
      }
      
      // Cancel existing notifications for this task first
      await _cancelTaskNotifications(task);
      
      final now = DateTime.now();
      final dueDate = task.dueDate;
      
      // Skip if due date is in the past
      if (dueDate.isBefore(now)) {
        print('TaskNotificationManager: Task ${task.id} due date is in the past, skipping notification');
        return;
      }
      
      print('TaskNotificationManager: Scheduling notifications for task: ${task.title}');
      print('  Due date: $dueDate');
      print('  Priority: ${task.priority}');
      
      // Calculate notification times based on priority
      final notificationTimes = _calculateNotificationTimes(dueDate, task.priority);
      
      // IMPORTANT: Always add a notification exactly at the due time
      notificationTimes.add(dueDate);
      
      // Sort notification times to ensure proper order
      notificationTimes.sort();
      
      int notificationIndex = 0;
      for (DateTime notificationTime in notificationTimes) {
        if (notificationTime.isAfter(now.subtract(const Duration(minutes: 1)))) { // Allow 1 minute buffer for due time
          final notificationId = _generateNotificationId(task.id!, notificationIndex);
          
          // Determine the urgency and message based on timing
          String urgencyText;
          String titlePrefix;
          
          if (notificationTime.isAtSameMomentAs(dueDate) || 
              notificationTime.difference(dueDate).abs() < const Duration(minutes: 2)) {
            // This is the due time notification
            urgencyText = 'DUE NOW!';
            titlePrefix = '🔥 TASK DUE';
          } else {
            // This is a reminder notification
            final timeUntilDue = dueDate.difference(notificationTime);
            urgencyText = _getUrgencyText(timeUntilDue);
            titlePrefix = '${_getPriorityEmoji(task.priority)} Task Deadline $urgencyText';
          }
          
          await _notificationService.scheduleTaskDeadlineNotification(
            id: notificationId,
            title: titlePrefix,
            body: '${task.title}\n📅 Due: ${_formatDueDate(dueDate)}${task.description != null ? '\n📝 ${task.description}' : ''}',
            scheduledDate: notificationTime,
            taskId: task.id!,
          );
          
          print('  ✓ Scheduled notification $notificationIndex for ${_formatDueDate(notificationTime)} ($urgencyText)');
        }
        notificationIndex++;
      }
      
    } catch (e) {
      print('TaskNotificationManager: Error scheduling notifications for task ${task.id}: $e');
    }
  }

  /// Cancel all notifications for a specific task
  Future<void> _cancelTaskNotifications(Task task) async {
    try {
      if (task.id == null) return;
      
      // Cancel all possible notifications for this task (up to 5 notifications per task)
      for (int i = 0; i < 5; i++) {
        final notificationId = _generateNotificationId(task.id!, i);
        await _notificationService.flutterLocalNotificationsPlugin.cancel(notificationId);
      }
      
      print('TaskNotificationManager: Cancelled notifications for task: ${task.title}');
    } catch (e) {
      print('TaskNotificationManager: Error cancelling notifications for task ${task.id}: $e');
    }
  }

  /// Calculate notification times based on due date and priority
  List<DateTime> _calculateNotificationTimes(DateTime dueDate, TaskPriority priority) {
    final List<DateTime> notificationTimes = [];
    final now = DateTime.now();
    
    // Base notification times before deadline
    List<Duration> intervals = [];
    
    switch (priority) {
      case TaskPriority.urgent:
        intervals = [
          const Duration(days: 7),    // 1 week before
          const Duration(days: 3),    // 3 days before
          const Duration(days: 1),    // 1 day before
          const Duration(hours: 4),   // 4 hours before
          const Duration(hours: 1),   // 1 hour before
        ];
        break;
      case TaskPriority.high:
        intervals = [
          const Duration(days: 3),    // 3 days before
          const Duration(days: 1),    // 1 day before
          const Duration(hours: 4),   // 4 hours before
          const Duration(hours: 1),   // 1 hour before
        ];
        break;
      case TaskPriority.medium:
        intervals = [
          const Duration(days: 1),    // 1 day before
          const Duration(hours: 4),   // 4 hours before
          const Duration(hours: 1),   // 1 hour before
        ];
        break;
      case TaskPriority.low:
        intervals = [
          const Duration(days: 1),    // 1 day before
          const Duration(hours: 2),   // 2 hours before
        ];
        break;
    }
    
    // Calculate actual notification times
    for (Duration interval in intervals) {
      final notificationTime = dueDate.subtract(interval);
      if (notificationTime.isAfter(now.add(const Duration(minutes: 1)))) {
        notificationTimes.add(notificationTime);
      }
    }
    
    return notificationTimes;
  }

  /// Generate a unique notification ID for a task and notification index
  int _generateNotificationId(String taskId, int index) {
    // Create a hash-like ID from task ID and index
    final combined = '$taskId-$index';
    int hash = 0;
    for (int i = 0; i < combined.length; i++) {
      hash = ((hash << 5) - hash) + combined.codeUnitAt(i);
      hash = hash & hash; // Convert to 32-bit integer
    }
    return hash.abs() % 2147483647; // Ensure positive and within int range
  }

  /// Get urgency text based on time until due
  String _getUrgencyText(Duration timeUntilDue) {
    if (timeUntilDue.inDays > 6) {
      return 'Next Week';
    } else if (timeUntilDue.inDays > 2) {
      return 'in ${timeUntilDue.inDays} Days';
    } else if (timeUntilDue.inDays == 1) {
      return 'Tomorrow';
    } else if (timeUntilDue.inHours > 4) {
      return 'Today';
    } else if (timeUntilDue.inHours > 1) {
      return 'in ${timeUntilDue.inHours} Hours';
    } else {
      return 'Soon!';
    }
  }

  /// Get priority emoji
  String _getPriorityEmoji(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
        return '🚨';
      case TaskPriority.high:
        return '⚠️';
      case TaskPriority.medium:
        return '📋';
      case TaskPriority.low:
        return '📝';
    }
  }

  /// Format due date for display
  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateDay = DateTime(date.year, date.month, date.day);
    
    final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    
    if (dateDay == today) {
      return 'Today at $timeStr';
    } else if (dateDay == tomorrow) {
      return 'Tomorrow at $timeStr';
    } else {
      return '${date.day}/${date.month}/${date.year} at $timeStr';
    }
  }

  /// Start periodic deadline checker (runs every 15 minutes)
  void _startDeadlineChecker() {
    _deadlineCheckTimer?.cancel();
    
    // Run every 15 minutes for more responsive checking
    _deadlineCheckTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      _checkOverdueTasksAndNotify();
      _checkRecentlyDueTasksAndNotify(); // New method for recently due tasks
    });
    
    // Also run immediately
    _checkOverdueTasksAndNotify();
    _checkRecentlyDueTasksAndNotify();
    
    print('TaskNotificationManager: Started periodic deadline checker (every 15 minutes)');
  }

  /// Start real-time checker for immediate due time notifications (runs every minute)
  void _startRealTimeChecker() {
    _realTimeChecker?.cancel();
    
    // Run every minute for precise due time detection
    _realTimeChecker = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkTasksDueRightNow();
    });
    
    print('TaskNotificationManager: Started real-time checker (every 1 minute)');
  }

  /// Check for tasks that are due right now (within the current minute)
  Future<void> _checkTasksDueRightNow() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      final now = DateTime.now();
      final currentMinute = DateTime(now.year, now.month, now.day, now.hour, now.minute);
      final nextMinute = currentMinute.add(const Duration(minutes: 1));
      
      // Find tasks due in the current minute
      final QuerySnapshot dueNowTasksSnapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: currentUser.uid)
          .where('isCompleted', isEqualTo: false)
          .where('isArchived', isEqualTo: false)
          .where('isReminder', isEqualTo: true)
          .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(currentMinute))
          .where('dueDate', isLessThan: Timestamp.fromDate(nextMinute))
          .get();
      
      if (dueNowTasksSnapshot.docs.isNotEmpty) {
        print('TaskNotificationManager: Found ${dueNowTasksSnapshot.docs.length} tasks due right now');
        
        for (QueryDocumentSnapshot doc in dueNowTasksSnapshot.docs) {
          final task = Task.fromMap(doc.id, doc.data() as Map<String, dynamic>);
          
          // Send immediate "DUE NOW" notification
          await _notificationService.showImmediateNotification(
            title: '🚨 TASK DUE NOW: ${task.title}',
            body: 'This task is due right now!\n📅 Due: ${_formatDueDate(task.dueDate)}${task.description != null ? '\n📝 ${task.description}' : ''}',
            payload: 'due_right_now:${task.id}',
          );
          
          print('TaskNotificationManager: Sent immediate "DUE NOW" notification for: ${task.title}');
        }
      }
    } catch (e) {
      print('TaskNotificationManager: Error checking tasks due right now: $e');
    }
  }

  /// Check for recently due tasks (within last 30 minutes) and send notifications
  Future<void> _checkRecentlyDueTasksAndNotify() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      final now = DateTime.now();
      final recentPast = now.subtract(const Duration(minutes: 30)); // Check last 30 minutes
      
      final QuerySnapshot recentlyDueTasksSnapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: currentUser.uid)
          .where('isCompleted', isEqualTo: false)
          .where('isArchived', isEqualTo: false)
          .where('isReminder', isEqualTo: true)
          .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(recentPast))
          .where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .get();
      
      if (recentlyDueTasksSnapshot.docs.isNotEmpty) {
        print('TaskNotificationManager: Found ${recentlyDueTasksSnapshot.docs.length} recently due tasks');
        
        for (QueryDocumentSnapshot doc in recentlyDueTasksSnapshot.docs) {
          final task = Task.fromMap(doc.id, doc.data() as Map<String, dynamic>);
          
          // Check if we already sent a "due now" notification for this task
          // We'll use a simple time-based check to avoid spam
          final timeSinceDue = now.difference(task.dueDate);
          
          if (timeSinceDue.inMinutes <= 30 && timeSinceDue.inMinutes >= 0) {
            // Send "due now" notification
            await _notificationService.showImmediateNotification(
              title: '🔥 TASK DUE NOW: ${task.title}',
              body: 'This task just became due!\n📅 Due: ${_formatDueDate(task.dueDate)}${task.description != null ? '\n📝 ${task.description}' : ''}',
              payload: 'due_now_task:${task.id}',
            );
            
            print('TaskNotificationManager: Sent "due now" notification for task: ${task.title}');
          }
        }
      }
    } catch (e) {
      print('TaskNotificationManager: Error checking recently due tasks: $e');
    }
  }

  /// Check for overdue tasks and send immediate notifications
  Future<void> _checkOverdueTasksAndNotify() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      final now = DateTime.now();
      final QuerySnapshot overdueTasksSnapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: currentUser.uid)
          .where('isCompleted', isEqualTo: false)
          .where('isArchived', isEqualTo: false)
          .where('isReminder', isEqualTo: true)
          .where('dueDate', isLessThan: Timestamp.fromDate(now))
          .get();
      
      if (overdueTasksSnapshot.docs.isNotEmpty) {
        print('TaskNotificationManager: Found ${overdueTasksSnapshot.docs.length} overdue tasks');
        
        for (QueryDocumentSnapshot doc in overdueTasksSnapshot.docs) {
          final task = Task.fromMap(doc.id, doc.data() as Map<String, dynamic>);
          final overdueDuration = now.difference(task.dueDate);
          
          // Send overdue notification (immediate)
          await _notificationService.showImmediateNotification(
            title: '🔴 OVERDUE: ${task.title}',
            body: 'This task was due ${_formatOverdueDuration(overdueDuration)} ago.\n📅 Was due: ${_formatDueDate(task.dueDate)}${task.description != null ? '\n📝 ${task.description}' : ''}',
            payload: 'overdue_task:${task.id}',
          );
        }
      }
    } catch (e) {
      print('TaskNotificationManager: Error checking overdue tasks: $e');
    }
  }

  /// Format overdue duration
  String _formatOverdueDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays == 1 ? '' : 's'}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours == 1 ? '' : 's'}';
    } else {
      return '${duration.inMinutes} minute${duration.inMinutes == 1 ? '' : 's'}';
    }
  }

  /// Manually refresh task notifications (useful when user settings change)
  Future<void> refreshTaskNotifications() async {
    print('TaskNotificationManager: Manually refreshing task notifications...');
    await _startTaskListener();
  }

  /// Clean up resources
  Future<void> dispose() async {
    print('TaskNotificationManager: Disposing...');
    await _taskStreamSubscription?.cancel();
    _deadlineCheckTimer?.cancel();
    _realTimeChecker?.cancel();
    _taskStreamSubscription = null;
    _deadlineCheckTimer = null;
    _realTimeChecker = null;
  }

  /// Re-initialize after user authentication changes
  Future<void> reinitialize() async {
    print('TaskNotificationManager: Re-initializing after auth change...');
    await dispose();
    await initialize();
  }
}
