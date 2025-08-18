import 'package:aiassistant1/models/task.dart';
import 'package:aiassistant1/services/task_notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class TaskNotificationIntegration {
  static final TaskNotificationIntegration _instance = TaskNotificationIntegration._internal();
  factory TaskNotificationIntegration() => _instance;
  TaskNotificationIntegration._internal();

  final TaskNotificationService _notificationService = TaskNotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final FirebaseAuth _auth = FirebaseAuth.instance;
  
  StreamSubscription<QuerySnapshot>? _taskStreamSubscription;
  Timer? _overdueCheckTimer;

  /// Initialize automatic task notification scheduling
  Future<void> initialize() async {
    // Disabled for demo release
    return;
  }

  /// Reschedule notifications for all existing tasks (e.g., after boot)
  Future<void> _rescheduleExistingTasks() async {
    // Disabled for demo release
    return;
  }

  /// Start periodic checker for overdue tasks (every 5 minutes)
  void _startOverdueTaskChecker() {
    // Disabled for demo release
    _overdueCheckTimer?.cancel();
  }

  /// Check for overdue tasks and send immediate notifications
  Future<void> _checkForOverdueTasks() async {
    // Disabled for demo release
    return;
  }

  /// Start listening to task changes for automatic notification scheduling
  Future<void> _startTaskListener() async {
    // Disabled for demo release
    await _taskStreamSubscription?.cancel();
    _taskStreamSubscription = null;
    return;
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
    // Disabled for demo release
    return;
  }

  /// Verify that a notification was properly scheduled
  Future<void> _verifyNotificationScheduled(Task task) async {
    // Disabled for demo release
    return;
  }

  /// Handle task removed
  Future<void> _handleTaskRemoved(Task task) async {
    // Disabled for demo release
    return;
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
    // Disabled for demo release
    return;
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
