import 'subtask.dart'; 

enum TaskPriority { low, medium, high, urgent }

class Task {
  final String? id;
  final String title;
  final String? description;
  final DateTime dueDate;
  final bool isCompleted;
  final String userId;
  final String category;
  final TaskPriority priority;
  final bool isArchived;
  final bool isReminder;
  final List<Subtask> subtasks;

  Task({
    this.id,
    required this.title,
    this.description,
    required this.dueDate,
    this.isCompleted = false,
    required this.userId,
    this.category = 'other',
    this.priority = TaskPriority.medium,
    this.isArchived = false,
    this.isReminder = false,
    this.subtasks = const [], // default to empty list
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
      'userId': userId,
      'category': category,
      'priority': priority.toString().split('.').last,
      'isArchived': isArchived,
      'isReminder': isReminder,
      'subtasks': subtasks.map((s) => s.toMap()).toList(),
    };
  }

  factory Task.fromMap(String id, Map<String, dynamic> map) {
    return Task(
      id: id,
      title: map['title'] ?? '',
      description: map['description'],
      dueDate: DateTime.parse(map['dueDate']),
      isCompleted: map['isCompleted'] == 1 || map['isCompleted'] == true,
      userId: map['userId'] ?? '',
      category: map['category'] ?? 'other',
      priority: TaskPriority.values.firstWhere(
        (e) => e.toString().split('.').last == (map['priority'] ?? 'medium'),
        orElse: () => TaskPriority.medium,
      ),
      isArchived: map['isArchived'] == 1 || map['isArchived'] == true,
      isReminder: map['isReminder'] == 1 || map['isReminder'] == true,
      subtasks: (map['subtasks'] as List<dynamic>?)
              ?.map((s) => Subtask.fromMap(Map<String, dynamic>.from(s)))
              .toList() ??
          [],
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    String? userId,
    String? category,
    TaskPriority? priority,
    bool? isArchived,
    bool? isReminder,
    List<Subtask>? subtasks,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      isArchived: isArchived ?? this.isArchived,
      isReminder: isReminder ?? this.isReminder,
      subtasks: subtasks ?? this.subtasks,
    );
  }
}
