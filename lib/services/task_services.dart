import 'package:aiassistant1/models/task.dart';
import 'package:aiassistant1/services/database_helper.dart';
import 'dart:async';

enum TaskSortOption { dueDate, priority, title, category }

enum TaskViewFilter { active, completed, archived, all }

enum TaskOrReminderFilter { all, tasks, reminders }

class TaskService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Stream for the home screen
  Stream<List<Task>> getTasksStream({
    required String userId,
    required bool isArchived,
    bool? isReminder, // Null for all, true for reminders, false for tasks
  }) {
    return Stream.periodic(const Duration(seconds: 1)).asyncMap((_) async {
      return await _dbHelper.getTasks(
        userId: userId,
        isArchived: isArchived,
        isCompleted: isArchived ? null : false, // For active tasks, filter out completed ones
        isReminder: isReminder,
      );
    });
  }

  // Create a new task
  Future<Task> createTask(Task task) async {
    try {
      final taskId = await _dbHelper.createTask(task);
      return task.copyWith(id: taskId);
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
    return Stream.periodic(const Duration(seconds: 1)).asyncMap((_) async {
      bool? isArchived;
      bool? isCompleted;
      bool? isReminder;

      // Apply view filtering
      switch (filter) {
        case TaskViewFilter.active:
          isArchived = false;
          isCompleted = false;
          break;
        case TaskViewFilter.completed:
          isArchived = false;
          isCompleted = true;
          break;
        case TaskViewFilter.archived:
          isArchived = true;
          break;
        case TaskViewFilter.all:
          // No additional filtering needed
          break;
      }

      // Apply type filtering
      switch (typeFilter) {
        case TaskOrReminderFilter.tasks:
          isReminder = false;
          break;
        case TaskOrReminderFilter.reminders:
          isReminder = true;
          break;
        case TaskOrReminderFilter.all:
          // No additional filtering needed
          break;
      }

      String orderBy;
      switch (sortBy) {
        case TaskSortOption.dueDate:
          orderBy = 'dueDate';
          break;
        case TaskSortOption.priority:
          orderBy = 'priority';
          break;
        case TaskSortOption.title:
          orderBy = 'title';
          break;
        case TaskSortOption.category:
          orderBy = 'category';
          break;
      }

      List<Task> tasks = await _dbHelper.getTasks(
        userId: userId,
        isArchived: isArchived,
        isCompleted: isCompleted,
        isReminder: isReminder,
        orderBy: orderBy,
      );

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
      return await _dbHelper.getTask(taskId);
    } catch (e) {
      throw Exception('Failed to get task: $e');
    }
  }

  // Update a task
  Future<void> updateTask(Task task) async {
    try {
      await _dbHelper.updateTask(task);
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  // Archive a task
  Future<void> archiveTask(String taskId) async {
    try {
      await _dbHelper.archiveTask(taskId);
    } catch (e) {
      throw Exception('Failed to archive task: $e');
    }
  }

  // Unarchive a task (for trash/archived view)
  Future<void> unarchiveTask(String taskId) async {
    try {
      await _dbHelper.unarchiveTask(taskId);
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
      await _dbHelper.deleteTask(taskId);
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  // Toggle task completion
  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    try {
      await _dbHelper.toggleTaskCompletion(taskId, isCompleted);
    } catch (e) {
      throw Exception('Failed to toggle task completion: $e');
    }
  }

  // Get tasks for calendar view
  Stream<List<Task>> getTasksForCalendar(
    String userId,
    DateTime startDate,
    DateTime endDate, {
    TaskViewFilter filter = TaskViewFilter.all,
    TaskOrReminderFilter typeFilter = TaskOrReminderFilter.all,
  }) {
    return Stream.periodic(const Duration(seconds: 1)).asyncMap((_) async {
      bool? isArchived;
      bool? isCompleted;
      bool? isReminder;

      // Apply view filtering
      switch (filter) {
        case TaskViewFilter.active:
          isArchived = false;
          isCompleted = false;
          break;
        case TaskViewFilter.completed:
          isArchived = false;
          isCompleted = true;
          break;
        case TaskViewFilter.archived:
          isArchived = true;
          break;
        case TaskViewFilter.all:
          // No additional filtering needed
          break;
      }

      // Apply type filtering
      switch (typeFilter) {
        case TaskOrReminderFilter.tasks:
          isReminder = false;
          break;
        case TaskOrReminderFilter.reminders:
          isReminder = true;
          break;
        case TaskOrReminderFilter.all:
          // No additional filtering needed
          break;
      }

      return await _dbHelper.getTasks(
        userId: userId,
        isArchived: isArchived,
        isCompleted: isCompleted,
        isReminder: isReminder,
        startDate: startDate,
        endDate: endDate,
        orderBy: 'dueDate',
      );
    });
  }

  // Get task statistics
  Future<Map<String, int>> getTaskStats(String userId) async {
    try {
      return await _dbHelper.getTaskStats(userId);
    } catch (e) {
      throw Exception('Failed to get task stats: $e');
    }
  }

  // Search tasks
  Future<List<Task>> searchTasks(String userId, String query) async {
    try {
      final allTasks = await _dbHelper.getTasks(userId: userId);
      return allTasks.where((task) {
        return task.title.toLowerCase().contains(query.toLowerCase()) ||
               (task.description?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
               task.category.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      throw Exception('Failed to search tasks: $e');
    }
  }

  // Get tasks by category
  Future<List<Task>> getTasksByCategory(String userId, String category) async {
    try {
      return await _dbHelper.getTasks(
        userId: userId,
        category: category,
        isArchived: false,
      );
    } catch (e) {
      throw Exception('Failed to get tasks by category: $e');
    }
  }

  // Get overdue tasks
  Future<List<Task>> getOverdueTasks(String userId) async {
    try {
      final now = DateTime.now();
      final allTasks = await _dbHelper.getTasks(
        userId: userId,
        isArchived: false,
        isCompleted: false,
      );
      return allTasks.where((task) => task.dueDate.isBefore(now)).toList();
    } catch (e) {
      throw Exception('Failed to get overdue tasks: $e');
    }
  }

  // Get tasks due today
  Future<List<Task>> getTasksDueToday(String userId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      
      return await _dbHelper.getTasks(
        userId: userId,
        isArchived: false,
        startDate: startOfDay,
        endDate: endOfDay,
      );
    } catch (e) {
      throw Exception('Failed to get tasks due today: $e');
    }
  }

  // Get tasks due this week
  Future<List<Task>> getTasksDueThisWeek(String userId) async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      
      return await _dbHelper.getTasks(
        userId: userId,
        isArchived: false,
        startDate: startOfWeek,
        endDate: endOfWeek,
      );
    } catch (e) {
      throw Exception('Failed to get tasks due this week: $e');
    }
  }
}