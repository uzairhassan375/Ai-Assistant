class Subtask {
  final String title;
  final String description;
  final DateTime deadline;

  Subtask({
    required this.title,
    required this.description,
    required this.deadline,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'deadline': deadline.toIso8601String(),
    };
  }

  factory Subtask.fromMap(Map<String, dynamic> map) {
    return Subtask(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      deadline: DateTime.parse(map['deadline']),
    );
  }
}
