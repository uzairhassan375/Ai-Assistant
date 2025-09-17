import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aiassistant1/models/task.dart';
import 'package:aiassistant1/services/simple_notification_service.dart';

enum TaskSortOption { dueDate, priority, title, category }

enum TaskViewFilter { active, completed, archived, all }

enum TaskOrReminderFilter { all, tasks, reminders }

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'tasks';

  // Stream for the home screen
  Stream<List<Task>> getTasksStream({
    required String userId,
    required bool isArchived,
    bool? isReminder, // Null for all, true for reminders, false for tasks
  }) {
    Query query = _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('isArchived', isEqualTo: isArchived);

    // Re-enable the isCompleted filter to test the full compound query
    // For active tasks, we also filter out completed ones
    if (!isArchived) {
      query = query.where('isCompleted', isEqualTo: false);
    }

    if (isReminder != null) {
      query = query.where('isReminder', isEqualTo: isReminder);
    }

    // Re-enable orderBy to test if it causes indexing issues
    query = query.orderBy('dueDate');

    // Temporarily remove orderBy to test if it's causing indexing issues
    return query.snapshots().handleError((error) {
      // Check if it's a missing index error
      if (error.toString().contains('failed-precondition') || 
          error.toString().contains('index') ||
          error.toString().contains('The query requires an index')) {
        
        // Extract the index creation URL if available
        final match = RegExp(r'https://console\.firebase\.google\.com[^\s]+')
            .firstMatch(error.toString());
        if (match != null) {
          // Missing index detected
        } else {
          // Composite index needed
        }
      }
      throw error;
    }).map((snapshot) {
      final allDocs = snapshot.docs;
      
      final tasks = allDocs
          .map(
            (doc) {
              try {
                final task = Task.fromMap(doc.id, doc.data() as Map<String, dynamic>);
                return task;
              } catch (e) {
                return null;
              }
            }
          )
          .where((task) => task != null)
          .cast<Task>()
          .toList();

      return tasks;
    });
  }

  // Create a new task
  Future<Task> createTask(Task task) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(_collection)
          .add(task.toMap());
      return task.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  // Get tasks with filtering and sorting
  Stream<List<Task>> getTasks(
    String userId, {
    TaskSortOption sortBy = TaskSortOption.dueDate,
    TaskViewFilter filter = TaskViewFilter.all,
    TaskOrReminderFilter typeFilter = TaskOrReminderFilter.all,
  }) {
    Query query = _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId);

    // Apply view filtering (active, completed, archived, all)
    switch (filter) {
      case TaskViewFilter.active:
        query = query
            .where('isArchived', isEqualTo: false)
            .where('isCompleted', isEqualTo: false);
        break;
      case TaskViewFilter.completed:
        query = query
            .where('isCompleted', isEqualTo: true)
            .where('isArchived', isEqualTo: false);
        break;
      case TaskViewFilter.archived:
        query = query.where('isArchived', isEqualTo: true);
        break;
      case TaskViewFilter.all:
        // No additional filtering needed
        break;
    }

    // Apply type filtering (tasks, reminders, all)
    switch (typeFilter) {
      case TaskOrReminderFilter.tasks:
        query = query.where('isReminder', isEqualTo: false);
        break;
      case TaskOrReminderFilter.reminders:
        query = query.where('isReminder', isEqualTo: true);
        break;
      case TaskOrReminderFilter.all:
        // No additional filtering needed
        break;
    }

    // Apply sorting
    switch (sortBy) {
      case TaskSortOption.dueDate:
        query = query.orderBy('dueDate');
        break;
      case TaskSortOption.priority:
        query = query.orderBy('priority');
        break;
      case TaskSortOption.title:
        query = query.orderBy('title');
        break;
      case TaskSortOption.category:
        query = query.orderBy('category');
        break;
    }

    return query.snapshots().map((snapshot) {
      List<Task> tasks =
          snapshot.docs
              .map(
                (doc) =>
                    Task.fromMap(doc.id, doc.data() as Map<String, dynamic>),
              )
              .toList();

      // Additional sorting for priority since it's an enum
      if (sortBy == TaskSortOption.priority) {
        tasks.sort((a, b) => a.priority.index.compareTo(b.priority.index));
      }

      return tasks;
    });
  }

  // Get a single task by ID
  Future<Task?> getTask(String taskId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_collection).doc(taskId).get();
      if (doc.exists) {
        return Task.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get task: $e');
    }
  }

  // Update a task
  Future<void> updateTask(Task task) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(task.id)
          .update(task.toMap());
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  // Archive a task
  Future<void> archiveTask(String taskId) async {
    try {
      await _firestore.collection(_collection).doc(taskId).update({
        'isArchived': true,
      });
    } catch (e) {
      throw Exception('Failed to archive task: $e');
    }
  }

  // Unarchive a task (for trash/archived view)
  Future<void> unarchiveTask(String taskId) async {
    try {
      await _firestore.collection(_collection).doc(taskId).update({
        'isArchived': false,
      });
    } catch (e) {
      throw Exception('Failed to unarchive task: $e');
    }
  }

  // Delete a task permanently
  Future<void> deleteTaskPermanently(
    String taskId, {
    bool isReminder = false,
  }) async {
    try {
      await _firestore.collection(_collection).doc(taskId).delete();
      if (isReminder) {
        final notificationService = SimpleNotificationService();
        // Cancel notification using the task ID directly
        final notificationId = taskId.hashCode.abs() % 1000000;
        await notificationService.cancelNotificationById(notificationId);
      }
    } catch (e) {
      throw Exception('Failed to delete task permanently: $e');
    }
  }

  // Toggle task completion status
  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    try {
      await _firestore.collection(_collection).doc(taskId).update({
        'isCompleted': isCompleted,
      });
    } catch (e) {
      throw Exception('Failed to toggle task completion: $e');
    }
  }

  // Get tasks by date range
  Stream<List<Task>> getTasksByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate, {
    TaskViewFilter filter = TaskViewFilter.all,
    TaskOrReminderFilter typeFilter = TaskOrReminderFilter.all,
  }) {
    Query query = _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate));

    // Apply view filtering
    switch (filter) {
      case TaskViewFilter.active:
        query = query
            .where('isArchived', isEqualTo: false)
            .where('isCompleted', isEqualTo: false);
        break;
      case TaskViewFilter.completed:
        query = query
            .where('isCompleted', isEqualTo: true)
            .where('isArchived', isEqualTo: false);
        break;
      case TaskViewFilter.archived:
        query = query.where('isArchived', isEqualTo: true);
        break;
      case TaskViewFilter.all:
        // No additional filtering needed
        break;
    }

    // Apply type filtering
    switch (typeFilter) {
      case TaskOrReminderFilter.tasks:
        query = query.where('isReminder', isEqualTo: false);
        break;
      case TaskOrReminderFilter.reminders:
        query = query.where('isReminder', isEqualTo: true);
        break;
      case TaskOrReminderFilter.all:
        // No additional filtering needed
        break;
    }

    return query.orderBy('dueDate').snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => Task.fromMap(doc.id, doc.data() as Map<String, dynamic>),
          )
          .toList();
    });
  }
}
