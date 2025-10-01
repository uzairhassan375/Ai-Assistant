import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';
import '../models/subtask.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'tasks.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create tasks table
    await db.execute('''
      CREATE TABLE tasks(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        dueDate TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        userId TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'other',
        priority TEXT NOT NULL DEFAULT 'medium',
        isArchived INTEGER NOT NULL DEFAULT 0,
        isReminder INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Create subtasks table
    await db.execute('''
      CREATE TABLE subtasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        taskId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        deadline TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (taskId) REFERENCES tasks (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_tasks_userId ON tasks(userId)');
    await db.execute('CREATE INDEX idx_tasks_dueDate ON tasks(dueDate)');
    await db.execute('CREATE INDEX idx_tasks_isArchived ON tasks(isArchived)');
    await db.execute('CREATE INDEX idx_tasks_isCompleted ON tasks(isCompleted)');
    await db.execute('CREATE INDEX idx_tasks_isReminder ON tasks(isReminder)');
    await db.execute('CREATE INDEX idx_subtasks_taskId ON subtasks(taskId)');
  }

  // Generate a unique ID for tasks
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           (1000 + (DateTime.now().microsecond % 1000)).toString();
  }

  // Task CRUD operations
  Future<String> createTask(Task task) async {
    final db = await database;
    final id = _generateId();
    final now = DateTime.now().toIso8601String();
    
    await db.insert('tasks', {
      'id': id,
      'title': task.title,
      'description': task.description,
      'dueDate': task.dueDate.toIso8601String(),
      'isCompleted': task.isCompleted ? 1 : 0,
      'userId': task.userId,
      'category': task.category,
      'priority': task.priority.toString().split('.').last,
      'isArchived': task.isArchived ? 1 : 0,
      'isReminder': task.isReminder ? 1 : 0,
      'createdAt': now,
      'updatedAt': now,
    });

    // Insert subtasks if any
    for (final subtask in task.subtasks) {
      await db.insert('subtasks', {
        'taskId': id,
        'title': subtask.title,
        'description': subtask.description,
        'deadline': subtask.deadline.toIso8601String(),
        'isCompleted': 0,
      });
    }

    return id;
  }

  Future<List<Task>> getTasks({
    required String userId,
    bool? isArchived,
    bool? isCompleted,
    bool? isReminder,
    String? category,
    TaskPriority? priority,
    DateTime? startDate,
    DateTime? endDate,
    String? orderBy,
    bool ascending = true,
  }) async {
    final db = await database;
    
    String whereClause = 'userId = ?';
    List<dynamic> whereArgs = [userId];

    if (isArchived != null) {
      whereClause += ' AND isArchived = ?';
      whereArgs.add(isArchived ? 1 : 0);
    }

    if (isCompleted != null) {
      whereClause += ' AND isCompleted = ?';
      whereArgs.add(isCompleted ? 1 : 0);
    }

    if (isReminder != null) {
      whereClause += ' AND isReminder = ?';
      whereArgs.add(isReminder ? 1 : 0);
    }

    if (category != null) {
      whereClause += ' AND category = ?';
      whereArgs.add(category);
    }

    if (priority != null) {
      whereClause += ' AND priority = ?';
      whereArgs.add(priority.toString().split('.').last);
    }

    if (startDate != null) {
      whereClause += ' AND dueDate >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClause += ' AND dueDate <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    String orderByClause = '';
    if (orderBy != null) {
      orderByClause = '$orderBy ${ascending ? 'ASC' : 'DESC'}';
    } else {
      orderByClause = 'dueDate ASC';
    }

    final List<Map<String, dynamic>> taskMaps = await db.query(
      'tasks',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: orderByClause,
    );

    List<Task> tasks = [];
    for (final taskMap in taskMaps) {
      // Get subtasks for this task
      final List<Map<String, dynamic>> subtaskMaps = await db.query(
        'subtasks',
        where: 'taskId = ?',
        whereArgs: [taskMap['id']],
      );

      final subtasks = subtaskMaps.map((map) => Subtask.fromMap(map)).toList();

      tasks.add(Task.fromMap(taskMap['id'], {
        ...taskMap,
        'subtasks': subtasks.map((s) => s.toMap()).toList(),
      }));
    }

    return tasks;
  }

  Future<Task?> getTask(String taskId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [taskId],
    );

    if (maps.isNotEmpty) {
      final taskMap = maps.first;
      
      // Get subtasks for this task
      final List<Map<String, dynamic>> subtaskMaps = await db.query(
        'subtasks',
        where: 'taskId = ?',
        whereArgs: [taskId],
      );

      final subtasks = subtaskMaps.map((map) => Subtask.fromMap(map)).toList();

      return Task.fromMap(taskId, {
        ...taskMap,
        'subtasks': subtasks.map((s) => s.toMap()).toList(),
      });
    }
    return null;
  }

  Future<void> updateTask(Task task) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    await db.update(
      'tasks',
      {
        'title': task.title,
        'description': task.description,
        'dueDate': task.dueDate.toIso8601String(),
        'isCompleted': task.isCompleted ? 1 : 0,
        'category': task.category,
        'priority': task.priority.toString().split('.').last,
        'isArchived': task.isArchived ? 1 : 0,
        'isReminder': task.isReminder ? 1 : 0,
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: [task.id],
    );

    // Update subtasks
    await db.delete('subtasks', where: 'taskId = ?', whereArgs: [task.id]);
    for (final subtask in task.subtasks) {
      await db.insert('subtasks', {
        'taskId': task.id,
        'title': subtask.title,
        'description': subtask.description,
        'deadline': subtask.deadline.toIso8601String(),
        'isCompleted': 0,
      });
    }
  }

  Future<void> deleteTask(String taskId) async {
    final db = await database;
    await db.delete('subtasks', where: 'taskId = ?', whereArgs: [taskId]);
    await db.delete('tasks', where: 'id = ?', whereArgs: [taskId]);
  }

  Future<void> archiveTask(String taskId) async {
    final db = await database;
    await db.update(
      'tasks',
      {'isArchived': 1, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<void> unarchiveTask(String taskId) async {
    final db = await database;
    await db.update(
      'tasks',
      {'isArchived': 0, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    final db = await database;
    await db.update(
      'tasks',
      {
        'isCompleted': isCompleted ? 1 : 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  // Get task statistics
  Future<Map<String, int>> getTaskStats(String userId) async {
    final db = await database;
    
    final totalTasks = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM tasks WHERE userId = ?',
      [userId],
    )) ?? 0;

    final completedTasks = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM tasks WHERE userId = ? AND isCompleted = 1 AND isArchived = 0',
      [userId],
    )) ?? 0;

    final pendingTasks = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM tasks WHERE userId = ? AND isCompleted = 0 AND isArchived = 0',
      [userId],
    )) ?? 0;

    final archivedTasks = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM tasks WHERE userId = ? AND isArchived = 1',
      [userId],
    )) ?? 0;

    return {
      'total': totalTasks,
      'completed': completedTasks,
      'pending': pendingTasks,
      'archived': archivedTasks,
    };
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
